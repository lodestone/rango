module Arango
  module VertexCollection
    module Mixin
      def included(base)
        base.extend(Arango::VertexCollection::ClassMethods)
        base.include(Arango::VertexCollection::Vertexs)
      end
    end
  end
end
