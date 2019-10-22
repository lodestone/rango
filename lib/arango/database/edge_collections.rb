module Arango
  class Database
    module EdgeCollections
      # Retrieves all collections from the database.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @return [Array<Arango::EdgeCollection>]
      def all_edge_collections(exclude_system: true)
        Arango::EdgeCollection.all(exclude_system: exclude_system, database: self)
      end
      def batch_all_edge_collections(exclude_system: true)
        Arango::EdgeCollection.batch_all(exclude_system: exclude_system, database: self)
      end

      # Creates a new edge collection.
      # @param name [String] The name of the collection.
      # @return [Arango::Collection] The instance of the collection created.
      def create_edge_collection(name)
        Arango::EdgeCollection.new(name, type: :edge, database: self).create
      end
      def batch_create_edge_collection(name)
        Arango::EdgeCollection.new(name, type: :edge, database: self).batch_create
      end

      # Get collection from the database.
      # @param name [String] The name of the collection.
      # @return [Arango::Database]
      def get_edge_collection(name)
        Arango::EdgeCollection.get(name, database: self)
      end
      def batch_get_edge_collection(name)
        Arango::EdgeCollection.batch_get(name, database: self)
      end
      alias fetch_edge_collection get_edge_collection
      alias retrieve_edge_collection get_edge_collection
      alias batch_fetch_edge_collection batch_get_edge_collection
      alias batch_retrieve_edge_collection batch_get_edge_collection

      # Instantiates a new edge collection.
      # @param name [String] The name of the collection.
      # @return [Arango::Collection]
      def new_edge_collection(name)
        Arango::EdgeCollection.new(name, type: :edge, database: self)
      end

      # Retrieves a list of all collections.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @return [Array<String>] List of collection names.
      def list_edge_collections
        Arango::EdgeCollection.list(exclude_system: exclude_system, database: self)
      end
      def batch_list_edge_collections
        Arango::EdgeCollection.batch_list(exclude_system: exclude_system, database: self)
      end

      # Removes a collection.
      # @param name [String] The name of the collection.
      # @return nil
      def drop_edge_collection(name)
        Arango::EdgeCollection.drop(name, database: self)
      end
      def batch_drop_edge_collection(name)
        Arango::EdgeCollection.batch_drop(name, database: self)
      end
      alias delete_edge_collection drop_edge_collection
      alias destroy_edge_collection drop_edge_collection
      alias batch_delete_edge_collection batch_drop_edge_collection
      alias batch_destroy_edge_collection batch_drop_edge_collection

      # Check if collection exists.
      # @param name [String] Name of the collection
      # @return [Boolean]
      def exist_edge_collection?(name, exclude_system: true)
        Arango::EdgeCollection.exist?(name, database: self, exclude_system: exclude_system)
      end
      def batch_exist_edge_collection?(name, exclude_system: true)
        Arango::EdgeCollection.batch_exist?(name, database: self, exclude_system: exclude_system)
      end
      alias edge_collection_exist? exist_edge_collection?
    end
  end
end
