module Arango
  module DocumentCollection
    module ClassMethods
      def new(database: Arango.current_database, graph: nil,
              name:, id: nil, is_system: false, status: nil, type: :document,
              properties: {})
        case type
        when :document
          super(database: database, graph: graph,
                name: name, id: id, status: status, type: :document, is_system: is_system,
                properties: properties)
        when :edge
          Arango::EdgeCollection::Base.new(database: database, graph: graph,
                                           name: name, id: nil, is_system: false, status: status, type: :edge,
                                           properties: properties)
        else raise "unknown type"
        end
      end

      # Takes a hash and instantiates a Arango::DocumentCollection object from it.
      # @param collection_hash [Hash]
      # @return [Arango::DocumentCollection]
      def from_h(collection_hash, database: Arango.current_database)
        collection_hash = collection_hash.transform_keys! { |k| k.to_s.underscore.to_sym }
        collection_hash.merge!(database: database) unless collection_hash.key?(:database)
        if collection_hash.key?(:properties)
          collection_hash[:id] = collection_hash[:properties].delete(:id) if collection_hash[:properties].key?(:id)
          collection_hash[:name] = collection_hash[:properties].delete(:name) if collection_hash[:properties].key?(:name)
          collection_hash[:status] = collection_hash[:properties].delete(:status) if collection_hash[:properties].key?(:status)
          collection_hash[:type] = collection_hash[:properties].delete(:type) if collection_hash[:properties].key?(:type)
        end
        collection_hash[:type] = TYPES[collection_hash[:type]] if collection_hash[:type].is_a?(Integer)
        Arango::DocumentCollection::Base.new(**collection_hash)
      end

      # Takes a Arango::Result and instantiates a Arango::DocumentCollection object from it.
      # @param collection_result [Arango::Result]
      # @param properties_result [Arango::Result]
      # @return [Arango::DocumentCollection]
      def from_results(collection_result, properties_result, database: Arango.current_database)
        hash = collection_result ? {}.merge(collection_result.to_h) : {}
        hash[:properties] = properties_result
        from_h(hash, database: database)
      end

      def self.extended(base)
        # Retrieves all collections from the database.
        # @param exclude_system [Boolean] Optional, default true, exclude system collections.
        # @param database [Arango::Database]
        # @return [Array<Arango::DocumentCollection>]
        Arango.request_class_method(base, :all) do |exclude_system: true, database: Arango.current_database|
          query = { excludeSystem: exclude_system }
          { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| from_results({}, c.to_h, database: database) }}}
        end

        # Get collection from the database.
        # @param name [String] The name of the collection.
        # @param database [Arango::Database]
        # @return [Arango::Database]
        Arango.multi_request_class_method(base, :get) do |name:, database: Arango.current_database|
          requests = []
          first_get_result = nil
          requests << { get: "/_api/collection/#{name}", block: ->(result) { first_get_result = result.result }}
          requests << { get: "/_api/collection/#{name}/properties", block: ->(result) { from_results(first_get_result, result.raw_result, database: database) }}
          requests
        end
        base.singleton_class.alias_method :fetch, :get
        base.singleton_class.alias_method :retrieve, :get
        base.singleton_class.alias_method :batch_fetch, :batch_get
        base.singleton_class.alias_method :batch_retrieve, :batch_get

        # Retrieves a list of all collections.
        # @param exclude_system [Boolean] Optional, default true, exclude system collections.
        # @param database [Arango::Database]
        # @return [Array<String>] List of collection names.
        Arango.request_class_method(base, :list_all) do |exclude_system: true, database: Arango.current_database|
          query = { excludeSystem: exclude_system }
          { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| c[:name] }}}
        end

        # Retrieves a list of document collections.
        # @param exclude_system [Boolean] Optional, default true, exclude system collections.
        # @param database [Arango::Database]
        # @return [Array<String>] List of collection names.
        Arango.request_class_method(base, :list) do |exclude_system: true, database: Arango.current_database|
          query = { excludeSystem: exclude_system }
          { get: '_api/collection', query: query, block: ->(result) { result.result.select { |c| TYPES[c[:type]] == :document }.map { |c| c[:name] }}}
        end

        # Removes a collection.
        # @param name [String] The name of the collection.
        # @param database [Arango::Database]
        # @return nil
        Arango.request_class_method(base, :drop) do |name:, database: Arango.current_database|
          { delete: "_api/collection/#{name}" , block: ->(_) { nil }}
        end
        base.singleton_class.alias_method :delete, :drop
        base.singleton_class.alias_method :destroy, :drop
        base.singleton_class.alias_method :batch_delete, :batch_drop
        base.singleton_class.alias_method :batch_destroy, :batch_drop

        # Check if s document collection exists.
        # @param name [String] Name of the collection
        # @param database [Arango::Database]
        # @return [Boolean]
        Arango.request_class_method(base, :any_exists?) do |name:, exclude_system: true, database: Arango.current_database|
          query = { excludeSystem: exclude_system }
          { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| c[:name] }.include?(name) }}
        end

        # Check if s document collection exists.
        # @param name [String] Name of the collection
        # @param database [Arango::Database]
        # @return [Boolean]
        Arango.request_class_method(base, :exists?) do |name:, exclude_system: true, database: Arango.current_database|
          query = { excludeSystem: exclude_system }
          { get: '_api/collection', query: query, block: ->(result) { result.result.select { |c| TYPES[c[:type]] == :document }.map { |c| c[:name] }.include?(name) }}
        end
      end
    end
  end
end
