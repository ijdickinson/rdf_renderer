module RDFUI
  # This renderer renders a resource as a span containing the rdfs:label or
  # skos:preferredLabel. It will match any resource that has a label property.
  # The output rendering is defined by the template <tt>label_renderer.haml</tt>
  class LabelRenderer < RDF_Renderer
    def accept( node, model, context, types, options )
      model.contains( node, Jena::Vocab::RDFS::label ) || model.contains( node, Jena::Vocab.SKOS.label(true) ) if model
    end

    def priority
      10
    end
  end
end