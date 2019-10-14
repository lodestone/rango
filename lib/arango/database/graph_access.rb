module Arango
  class Database
    module GraphAccess
      # == GRAPH ==

      def create_graph

      end

      def graphs
        result = request("GET", "_api/gharial")
        return result if return_directly?(result)
        result[:graphs].map do |graph|
          Arango::Graph.new(database: self, name: graph[:_key], body: graph)
        end
      end

      def graph(name:, edge_definitions: [], orphan_collections: [],
                body: {})
        Arango::Graph.new(name: name, database: self, edge_definitions: edge_definitions, orphan_collections: orphan_collections, body: body)
      end

      def list_graphs
        # TODO
      end
    end
  end
end
