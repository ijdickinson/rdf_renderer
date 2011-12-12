%w[
  node_renderer
  rdf_renderer
  label_renderer
].each  {|f| require "rdf_renderer/#{f}"}
