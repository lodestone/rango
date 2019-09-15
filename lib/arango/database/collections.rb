module Arango
  class Database
    module Collections
      # Retrieves all collections from the database.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @return [Array<Arango::Collection>]
      def all_collections(exclude_system: true)
        Arango::Collection.all(exclude_system: exclude_system, database: self)
      end

      # Creates a new collection.
      # @param name [String] The name of the collection.
      # @param type [Symbol] One of :document or :edge, the collection type, optional, default: :document.
      # @return [Arango::Collection] The instance of the collection created.
      def create_collection(name, type: :document)
        Arango::Collection.new(name, type: type, database: self).create
      end

      # Creates a new edge collection.
      # @param name [String] The name of the collection.
      # @return [Arango::Collection] The instance of the collection created.
      def create_edge_collection(name)
        Arango::Collection.new(name, type: :edge, database: self).create
      end

      # Get collection from the database.
      # @param name [String] The name of the collection.
      # @return [Arango::Database]
      def get_collection(name)
        Arango::Collection.get(name, database: self)
      end
      alias fetch_collection get_collection
      alias retrieve_collection get_collection

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

      # Removes a collection.
      # @param name [String] The name of the collection.
      # @return nil
      def drop_collection(name)
        Arango::Collection.delete(name, database: self)
      end
      alias delete_collection drop_collection
      alias destroy_collection drop_collection

      # Check if collection exists.
      # @param name [String] Name of the collection
      # @return [Boolean]
      def exist_collection?(name)
        Arango::Collection.exist?(name, database: self)
      end
      alias collection_exist? exist_collection?
    end
  end
end
