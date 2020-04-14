module Arango
  module Graph
    module Mixin
      def self.included(base)
        base.extend(Arango::Graph::ClassMethods)
        base.include(Arango::Graph::InstanceMethods)
        # base.include(Arango::Graph::Definition)
        # base.include(Arango::Graph::EdgeCollections)
        # base.include(Arango::Graph::VertexCollections)
      end
    end
  end
end
