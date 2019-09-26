module Arango
  class Database
    module Collections
      # Retrieves all collections from the database.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @return [Array<Arango::Collection>]
      def all_collections(exclude_system: true)
        Arango::Collection.all(exclude_system: exclude_system, database: self)
      end
      def batch_all_collections(exclude_system: true)
        Arango::Collection.batch_all(exclude_system: exclude_system, database: self)
      end

      # Creates a new collection.
      # @param name [String] The name of the collection.
      # @param type [Symbol] One of :document or :edge, the collection type, optional, default: :document.
      # @return [Arango::Collection] The instance of the collection created.
      def create_collection(name, type: :document, is_system: false)
        Arango::Collection.new(name, type: type, database: self, is_system: is_system).create
      end
      def batch_create_collection(name, type: :document, is_system: false)
        Arango::Collection.new(name, type: type, database: self, is_system: is_system).batch_create
      end

      # Creates a new edge collection.
      # @param name [String] The name of the collection.
      # @return [Arango::Collection] The instance of the collection created.
      def create_edge_collection(name)
        Arango::Collection.new(name, type: :edge, database: self).create
      end
      def batch_create_edge_collection(name)
        Arango::Collection.new(name, type: :edge, database: self).batch_create
      end

      # Get collection from the database.
      # @param name [String] The name of the collection.
      # @return [Arango::Database]
      def get_collection(name)
        Arango::Collection.get(name, database: self)
      end
      def batch_get_collection(name)
        Arango::Collection.batch_get(name, database: self)
      end
      alias fetch_collection get_collection
      alias retrieve_collection get_collection
      alias batch_fetch_collection batch_get_collection
      alias batch_retrieve_collection batch_get_collection

      # Instantiates a new collection.
      # @param name [String] The name of the collection.
      # @param type [Symbol] One of :document or :edge, the collection type, optional, default: :document.
      # @return [Arango::Collection]
      def new_collection(name, type: :document)
        Arango::Collection.new(name, type: type, database: self)
      end

      # Instantiates a new edge collection.
      # @param name [String] The name of the collection.
      # @return [Arango::Collection]
      def new_edge_collection(name)
        Arango::Collection.new(name, type: :edge, database: self)
      end

      # Retrieves a list of all collections.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @return [Array<String>] List of collection names.
      def list_collections(exclude_system: true)
        Arango::Collection.list(exclude_system: exclude_system, database: self)
      end
      def batch_list_collections(exclude_system: true)
        Arango::Collection.batch_list(exclude_system: exclude_system, database: self)
      end

      # Removes a collection.
      # @param name [String] The name of the collection.
      # @return nil
      def drop_collection(name)
        Arango::Collection.drop(name, database: self)
      end
      def batch_drop_collection(name)
        Arango::Collection.batch_drop(name, database: self)
      end
      alias delete_collection drop_collection
      alias destroy_collection drop_collection
      alias batch_delete_collection batch_drop_collection
      alias batch_destroy_collection batch_drop_collection

      # Check if collection exists.
      # @param name [String] Name of the collection
      # @return [Boolean]
      def exist_collection?(name, exclude_system: true)
        Arango::Collection.exist?(name, database: self, exclude_system: exclude_system)
      end
      def batch_exist_collection?(name, exclude_system: true)
        Arango::Collection.batch_exist?(name, database: self, exclude_system: exclude_system)
      end
      alias collection_exist? exist_collection?
    end
  end
end
