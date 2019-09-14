module Arango
  class Database
    module Collections
      # Get all collections.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @return [Array] Array of Arango::Collection
      def all_collections(exclude_system: true)
        Arango::Collection.all(exclude_system: exclude_system, database: self)
      end

      def create_collection(name, type: :document)
        Arango::Collection.new(name, type: type, database: self).create
      end

      def create_edge_collection(name)
        Arango::Collection.new(name, type: :edge, database: self).create
      end

      def get_collection(name)
        Arango::Collection.get(name, database: self)
      end
      alias fetch_collection get_collection
      alias retrieve_collection get_collection

      def new_collection(name, type: :document)
        Arango::Collection.new(name, type: type, database: self)
      end

      def new_edge_collection(name)
        Arango::Collection.new(name, type: :edge, database: self)
      end

      def list_collections(exclude_system: true)
        Arango::Collection.list(exclude_system: exclude_system, database: self)
      end

      def drop_collection(name)
        Arango::Collection.delete(name, database: self)
      end
      alias delete_collection drop_collection
      alias destroy_collection drop_collection

      def exist_collection?(name)
        Arango::Collection.exist?(name, database: self)
      end
      alias collection_exist? exist_collection?
    end
  end
end
