module Arango
  module Helper
    module Traversal
      def traversal(body: {}, direction: nil, edge_collection: nil, expander: nil, filter: nil, init: nil, item_order: nil, max_depth: nil,
                    max_iterations: nil, min_depth: nil, order: nil, sort: nil, strategy: nil, uniqueness: nil, visitor: nil)
        Arango::Traversal.new(body: body, direction: direction, edge_collection: edge_collection, expander: expander, filter: filter, init: init,
                              item_order: item_order, max_depth: max_depth, max_iterations: max_iterations, min_depth: min_depth, order: order,
                              sort: sort, strategy: strategy, uniqueness: uniqueness, vertex: self, visitor: visitor)
      end
    end
  end
end