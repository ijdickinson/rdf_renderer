class TestResourceRenderer1 < RDFUI::RDF_Renderer
  def accept( node, model, context, types, options = {} )
    types.include?( :test_type_1 )
  end

  def render( options )
    "template1"
  end

  def priority
    2
  end
end

class TestResourceRenderer2 < RDFUI::RDF_Renderer
  def accept( node, model, context, types, options = {} )
    types.include?( :test_type_2 )
  end

  def render( options)
    "template2"
  end

  def priority
    2
  end
end
