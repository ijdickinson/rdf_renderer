require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "NodeRenderer" do
  subject {RDFUI::NodeRenderer.instance}

  before(:each) do
    subject.reset
  end

  it "should have a singleton instance" do
    subject.should_not be_nil
    t = RDFUI::NodeRenderer.instance
    t.should equal(subject)
  end

  it "should allow the log option to be set" do
    subject.log.should be_nil
    subject.log = :testlog
    subject.log.should == :testlog

    t = RDFUI::NodeRenderer.new( :log => :testlog1 )
    t.log.should == :testlog1
  end

  it "should allow the default model option to be set" do
    subject.default_model.should be_nil
    subject.default_model = :testmodel
    subject.default_model.should == :testmodel

    t = RDFUI::NodeRenderer.new( :default_model => :testmodel1)
    t.default_model.should == :testmodel1
  end

  it "should allow the default context option to be set" do
    subject.default_context.should == :any
    subject.default_context = :testcontext
    subject.default_context.should == :testcontext

    t = RDFUI::NodeRenderer.new( :default_context => :testcontext1)
    t.default_context.should == :testcontext1
  end

  it "should allow the render proc option to be set" do
    subject.render_proc.should be_kind_of( Proc )
    subject.render_proc = :testproc
    subject.render_proc.should == :testproc

    t = RDFUI::NodeRenderer.new( :render_proc => :testproc1)
    t.render_proc.should == :testproc1
  end

  it "should pick the right renderer for a type" do
    node1 = object_with_types( :test_type_1 )
    node2 = object_with_types( :test_type_2 )

    template = subject.select_renderer( node1, :context, {:types => [:test_type_1]} ).render( {} )
    template.should == "template1"

    template = subject.select_renderer( node2, :context, {:types => [:test_type_2]} ).render( {} )
    template.should == "template2"
  end

  it "should generate a view by picking the renderer" do
    node1 = mock_resource( :test_type_1 )

    view = subject.view( :node => node1 )
    view.should == "template1\n"
  end

  it "should use the label renderer for an RDFS label" do
    m = Jena::Core::ModelFactory.createDefaultModel
    m.setNsPrefix( "rdfs", Jena::Vocab::RDFS.getURI )
    r = m.createResource( "http://example.com/r" )
    r.addProperty( Jena::Vocab::RDFS.label, "test label 1" )
    r.addProperty( Jena::Vocab::RDF.type, Jena::Vocab::RDFS::Class)
    view = subject.view( :node => r )
    view.should match( /test label 1/ )
    view.should match( /span class='rdf_resource Class'/ )
  end
end
