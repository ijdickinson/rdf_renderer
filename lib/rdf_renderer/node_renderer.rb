# A collection of classes to help with an RDF presentation layer.
module RDFUI

  # Provides a means to render an RDF node (resource or literal) into a presentation form
  # suitable for display (e.g. HTML). The choice of renderer for a given node depends on
  # attributes of the node itself (e.g. type or other properties), and the current *context*.
  # The context is simply a token, but which allows for rendering to be customised to, for
  # example, a list (requiring a short summary) or a details page.
  #
  # The renderer is pluggable. A new renderer is declared simply by making it a sub-class
  # of +RDFRenderer+. +RDFRenderer+ responds to +priority+, which allows some renderers
  # to act as defaults while others are specialised for particular node types. The main
  # rendering method is +view+.
  #
  # The rendering engine used may be defined by setting the +render_proc+ to a Proc with
  # two arguments: +template+ and +options+, denoting the template to be renderered and
  # the accumulated hash of option arguments. The default rendering engine is Haml. Haml
  # templates will have two additional local methods defined: +view+ and +render+, which
  # will invoke the corresponding methods on the +NodeRenderer+ instance doing the rendering.
  # This allows templates to nest, or delegate the rendering of enclosed elements back
  # to the renderer.
  class NodeRenderer
    # Jena +Model+ to use by default
    attr_accessor :default_model

    # Send debug output to this log object if non-nil
    attr_accessor :log

    # Default context symbol, used when no explicit context is passed to the +view+ method
    attr_accessor :default_context

    # Rendering proc: this block is invoked to turn a template name or description into output form. Default is to use Haml
    attr_accessor :render_proc

    # Return a singleton instance of +NodeRenderer+, for cases where a single renderer is shared
    # by different classes. Lazily created on first call.
    def self.instance
      @@instance ||= self.new
    end

    # Create a new +NodeRenderer+ with the given options.
    #
    # * <tt>:default_model</tt> - a Jena +Model+ which will be assume to be the source of statements about
    #   the node to be rendered
    # * <tt>:log</tt> - a +Logger+ instance which will be used to log the progress of the renderer
    # * <tt>:default_context</tt> - a symbol denoting the default context; default value is +:any+
    def initialize( options = {} )
      @default_context = :any
      @render_proc = default_render_proc

      options.each do |opt,value|
        case opt
        when :placeholder
          # put special option handling here
        else
          self.send( "#{opt}=", value )
        end
      end
    end

    # Generate a presentation of an RDF node, denoted by the +:node+ option. The options
    # is passed to the call to the actual renderer, so may be used to convey parameters
    # to later method calls. This renderer object is automatically passed along as the
    # +:node_renderer+ option.
    #
    # * <tt>:node</tt> - the RDF node to be rendered
    # * <tt>:context</tt> - the context to use; if +nil+, the +default_context+ will be used instead
    # * <tt>:model</tt> - the Jena RDF +Model+ to use; if nil, use the model attached to +:node+ or the +:default_model+
    def view( options )
      t = Time.new
      log.debug( "NodeRenderer#view: #{options.inspect}" ) if log

      node = options[:node] || options["node"]
      return "<div class='warning'>No node to render!</div>" unless node
      return "<div class='warning'>Not an RDF node: #{node.inspect}</div>" unless node.is_a?( Jena::Core::RDFNode )

      options[:context] = options[:context] || options["context"] || default_context
      options[:node_renderer] = self
      options[:model] = get_model( options )
      options[:types] = node.types

      r = select_renderer( node, options[:context], options )
      result = render( r.render( options ), options )

      log.debug( "NodeRenderer#view time taken = #{t - Time.now}s" ) if log
      result
    end

    # Enact the rendering that was returned by the selected renderer. If +template+
    # is a symbol or string, we pass it to the render proc to render, which will
    # typically defer to a templating engine such as Haml. If +template+ is itself
    # a proc, we invoke it with the optionuments
    # * +template+ - symbol, string or +Proc+ denoting the template to render
    # * +options+ - hash of options to pass information to render, including the +node+ to be rendered
    def render( template, options )
      return template.call( options ) if template.is_a? Proc
      return render_proc.call( template, options ) if template
      "<p class='warning'>Could not find a matching renderer for node #{options[:node]}<br />Args: #{options.inspect}</p>"
    end

    # Identify the model to be used as the source of RDF information. Priority is:
    # * <tt>options[:node]</tt>
    # * the model attached to the +:node+ if the node is a resource
    # * the default model
    def get_model( options )
      return options[:model] if options[:model]
      return options[:node].getModel if options[:node] && options[:node].resource? && options[:node].getModel
      default_model
    end

    # Select a renderer for the given node and context, by asking all registered renderers
    # if they will +accept+ the given node with its context and, for efficiency, known types.
    def select_renderer( node, context, options )
      selected = nil

      RDF_Renderer.renderers.each do |rend|
        accepted = rend.accept( node, get_model( options ), context, options[:types], options )
        selected = rend if accepted && (!selected || rend.priority > selected.priority)
      end

      log.debug( "selected renderer = #{selected.inspect}") if log
      selected
    end

    # Returns the default render proc, which uses Haml to convert a string template
    # or symbol naming a template into the output form
    #
    # The +render_proc+ should take arguments:
    # * <tt>template</tt> - the name or content of the template
    # * <tt>options</tt> - hash of the rendering options, including the subject +node+
    def default_render_proc
      lambda do |template, options|
        HamlWrapper.view( template, options )
      end
    end

    # Reset back to default options. Primarily used in testing.
    def reset
      initialize
      @log = nil
      @default_model = nil
    end
  end

  # Simple wrapper for Haml engine.
  # TODO: add some caching of templates
  class HamlWrapper
    # Load a Haml template from a file, using the current load path as a place
    # to search for templates.
    def self.load_template_file( template_file )
      template_file = template_file.to_s
      template_file += ".haml" unless template_file.end_with? ".haml"
      template = nil

      $LOAD_PATH.each do |dir|
        f = File.join(dir, template_file)
        if File.exists?(f)
          template = IO.read(f)
          break
        end
      end

      template || "<p class='warning'>Failed to find template #{template_file}</p>"
    end

    # Render the given template using the Haml engine
    def self.view( template, options )
      template = load_template_file( template ) if template.is_a? Symbol
      env = {}
      options.each {|k,v| env[HamlWrapper.as_ruby_safe_sym(k)] = v}

      nr = options[:node_renderer]
      env[:view] = lambda {|options| nr.view( options )}
      env[:render] = lambda {|template,options| nr.render( template, options )}

      Haml::Engine.new(template).render(Object.new, env)
    end

    # Ensure that a variable name does not contain a punctuation character
    # which will cause a problem when Haml makes local variables of the passed-in
    # template arguments
    def self.as_ruby_safe_sym( s )
      return s unless s.is_a?(String) && s =~ /[[:punct:]]/
      s.to_s.gsub( /[[:punct:]]/, '_' ).to_sym
    end

    # Return true if we can be sure we're in production mode, which turns on
    # the caching
    def self.production_mode?( options )
      false
    end
  end

end
