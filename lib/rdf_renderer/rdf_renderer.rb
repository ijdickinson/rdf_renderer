module RDFUI
  class RDF_Renderer
    # Default template name is the class name converted from CamelCase to
    # underscore. So the template for this class would be typed_renderer.haml
    def template_name
      un_camelcase( self.class.name ).gsub( /^.*\//, "" ).to_sym
    end

    # Default priority for renderers is one
    def priority
      1
    end

    # Keep track of all of the new renderer subclasses that get loaded
    def self.inherited( subclass )
      @@renderers ||= Set.new
      @@renderers << subclass.new
    end

    # Return an array of registered renderer instances
    def self.renderers
      @@renderers ||= []
    end

    # Return an array of the class names registered renderer instances
    def self.renderer_names
      renderers.map {|r| r.class.name}
    end

    # Return true if this renderer will accept the given node in the given
    # context. Default is always accept.
    #
    # * +node+ - the node that is being rendered
    # * +model+ - the Jena +Model+ containing RDF information
    # * +context+ - the current context symbol
    # * +types+ - the set of types of +node+
    # * +options+ - hash of other method options
    def accept( node, model, context, types, options = {} )
      true
    end

    # Render the node, given the context and arguments. Default is to return
    # a template name to be invoked by a templating engine, but this method
    # may return a lambda which will be invoked to perform the rendering directly.
    #
    # * <tt>:node</tt> - the RDF node to be rendered
    # * <tt>:context</tt> - the current context
    # * <tt>:node_renderer</tt> - the current +NodeRenderer+
    def render( args )
      template_name
    end

    # Empty the list of known renderer sub-classes
    def self.forget_all
      @@renderers.clear
    end

    :private
    # Convert a camel-case name to one using underscore name separators
    #    un_camelcase( fooBar19-20 ) # => foo_bar_19_20
    def un_camelcase( s )
      s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

  end

end