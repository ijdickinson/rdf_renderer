require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RDF_Renderer base class" do
  before(:each) do
    # aka setUp()
  end

  subject {RDFUI::RDF_Renderer.new}

  it "should have priority one in the base renderer" do
    subject.priority.should == 1
  end

  it "should have a template name which matches the class" do
    subject.template_name.should == :rdf_renderer
  end

  it "should accept anything by default" do
    subject.accept( :node, :context, [] ).should be_true
  end

  it "should return the template name as the default rendering" do
    subject.render( {} ).should == :rdf_renderer
  end

  it "should track new renderers as they are defined" do
    RDFUI::RDF_Renderer.renderer_names.should_not include( "TestRenderer001" )
    n = RDFUI::RDF_Renderer.renderers().length

    class TestRenderer001 < RDFUI::RDF_Renderer
    end

    RDFUI::RDF_Renderer.renderers.length.should == (n + 1)
    RDFUI::RDF_Renderer.renderer_names.should include( "TestRenderer001" )
  end
end