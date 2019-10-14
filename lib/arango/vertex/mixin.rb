module Arango
  module Vertex
    module Mixin
      def included(base)
        base.extend(Arango::Helper::RequestMethod)
        base.extend(Arango::Vertex::ClassMethods)
        base.include(Arango::Vertex::InstanceMethods)
      end
    end
  end
end
