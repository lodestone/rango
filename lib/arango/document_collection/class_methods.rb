module Arango
  module DocumentCollection
    module ClassMethods
      # Takes a hash and instantiates a Arango::Collection object from it.
      # @param collection_hash [Hash]
      # @return [Arango::Collection]
      def from_h(collection_hash, database: nil)
        collection_hash = collection_hash.transform_keys { |k| k.to_s.underscore.to_sym }
        collection_hash.merge!(database: database) if database
        %i[code error].each { |key| collection_hash.delete(key) }
        instance_variable_hash = {}
        %i[cache_enabled globally_unique_id id object_id].each do |key|
          instance_variable_hash[key] = collection_hash.delete(key)
        end
        collection = Arango::Collection.new(collection_hash.delete(:name), **collection_hash)
        instance_variable_hash.each do |k,v|
          collection.instance_variable_set("@#{k}", v)
        end
        collection
      end

      # Takes a Arango::Result and instantiates a Arango::Collection object from it.
      # @param collection_result [Arango::Result]
      # @param properties_result [Arango::Result]
      # @return [Arango::Collection]
      def from_results(collection_result, properties_result, database: nil)
        hash = {}.merge(collection_result.to_h)
        %i[cache_enabled globally_unique_id id key_options object_id wait_for_sync].each do |key|
          hash[key] = properties_result[key]
        end
        from_h(hash, database: database)
      end

      # Retrieves all collections from the database.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @param database [Arango::Database]
      # @return [Array<Arango::Collection>]
      Arango.request_class_method(Arango::Collection, :all) do |exclude_system: true, database: Arango.current_database|
        query = { excludeSystem: exclude_system }
        { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| from_h(c.to_h, database: database) }}}
      end

      # Get collection from the database.
      # @param name [String] The name of the collection.
      # @param database [Arango::Database]
      # @return [Arango::Database]
      Arango.multi_request_class_method(Arango::Collection, :get) do |name, database: Arango.current_database|
        requests = []
        first_get_result = nil
        requests << { get: "/_api/collection/#{name}", block: ->(result) { first_get_result = result }}
        requests << { get: "/_api/collection/#{name}/properties", block: ->(result) { from_results(first_get_result, result, database: database) }}
        requests
      end
      alias fetch get
      alias retrieve get
      alias batch_fetch batch_get
      alias batch_retrieve batch_get

      # Retrieves a list of all collections.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @param database [Arango::Database]
      # @return [Array<String>] List of collection names.
      Arango.request_class_method(Arango::Collection, :list) do |exclude_system: true, database: Arango.current_database|
        query = { excludeSystem: exclude_system }
        { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| c[:name] }}}
      end

      # Removes a collection.
      # @param name [String] The name of the collection.
      # @param database [Arango::Database]
      # @return nil
      Arango.request_class_method(Arango::Collection, :drop) do |name, database: Arango.current_database|
        { delete: "_api/collection/#{name}" , block: ->(_) { nil }}
      end
      alias delete drop
      alias destroy drop
      alias batch_delete batch_drop
      alias batch_destroy batch_drop

      # Check if collection exists.
      # @param name [String] Name of the collection
      # @param database [Arango::Database]
      # @return [Boolean]
      Arango.request_class_method(Arango::Collection, :exist?) do |name, exclude_system: true, database: Arango.current_database|
        query = { excludeSystem: exclude_system }
        { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| c[:name] }.include?(name) }}
      end
    end
  end
end
