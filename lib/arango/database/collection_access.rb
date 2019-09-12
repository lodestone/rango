module Arango
  class Database
    module CollectionAccess
      # == COLLECTION ==
      # verified, in js api
      def create_collection

      end

      def collection(name)
        Arango::DocumentCollection.new(name: name, database: self)
      end

      # verified
      def collections(exclude_system: true)
        # TODO Fetches all collections from the database and returns an array of DocumentCollection and EdgeCollection instances for the collections
      end

      def edge_collection(name)
        # TODO Return edge collection
      end

      # verified, in js api
      def list_collections(exclude_system: true)
        query = { excludeSystem: exclude_system }
        result = request("GET", "_api/collection", query: query)
        return result if return_directly?(result)
        result[:result].map do |x|
          Arango::DocumentCollection.new(database: self, name: x[:name], body: x )
        end
      end
    end
  end
end