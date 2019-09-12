module Arango
  module Graph
    module Basics
      def create(is_smart: @is_smart, smart_graph_attribute: @smart_graph_attribute,
                 number_of_shards: @number_of_shards)
        body = {
          name: @name,
          edgeDefinitions:   edge_definitions_raw,
          orphanCollections: orphan_collections_raw,
          isSmart: is_smart,
          options: {
            smartGraphAttribute: smart_graph_attribute,
            numberOfShards: number_of_shards
          }
        }
        body[:options].delete_if{|k,v| v.nil?}
        body.delete(:options) if body[:options].empty?
        result = @database.request("POST", "_api/gharial", body: body, key: :graph)
        return_element(result)
      end

      def exist?

      end
      alias exists? exist?

      def info

      end

      def drop(dropCollections: nil)
        query = { dropCollections: dropCollections }
        result = @database.request("DELETE", "_api/gharial/#{@name}", query: query,
                                   key: :removed)
        return_delete(result)
      end
    end
  end
end