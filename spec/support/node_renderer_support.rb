# Return a new object which responds to :types with the given values
def object_with_types( *given_types )
  obj = Object.new
  obj.expects(:types).returns( given_types ).at_least(0)
  obj
end

def mock_resource( *given_types )
  resource = object_with_types( *given_types )
  resource.expects(:'resource?').at_least(0).returns( true )
  resource.expects(:getModel).at_least(0).returns( nil )
  resource.expects(:'is_a?').at_least(0).returns( true )
  resource
end