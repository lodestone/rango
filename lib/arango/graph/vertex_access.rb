module Arango
  module Graph
    module VertexAccess
      def vertex_collection

      end

      def vertex_collections
        result = request("GET", "vertex", key: :collections)
        return result if return_directly?(result)
        result.map do |x|
          Arango::DocumentCollection.new(name: x, database: @database, graph: self)
        end
      end

      def add_vertex_collection(collection:)
        satisfy_class?(collection, [String, Arango::DocumentCollection])
        collection = collection.is_a?(String) ? collection : collection.name
        body = { collection: collection }
        result = request("POST", "vertex", body: body, key: :graph)
        return_element(result)
      end

      def remove_vertex_collection(collection:, dropCollection: nil)
        query = {dropCollection: dropCollection}
        satisfy_class?(collection, [String, Arango::DocumentCollection])
        collection = collection.is_a?(String) ? collection : collection.name
        result = request("DELETE", "vertex/#{collection}", query: query, key: :graph)
        return_element(result)
      end
    end
  end
end