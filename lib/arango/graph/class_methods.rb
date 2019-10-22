module Arango
  module Graph
    module ClassMethods
      def from_h(graph_hash, database: nil)
        graph_hash = graph_hash.transform_keys { |k| k.to_s.underscore.to_sym }
        graph_hash.merge!(database: database) if database
        %i[code error].each { |key| graph_hash.delete(key) }
        instance_variable_hash = {}
        %i[cache_enabled globally_unique_id id object_id].each do |key|
          instance_variable_hash[key] = graph_hash.delete(key)
        end
        graph = Arango::Graph::Base.new(graph_hash.delete(:name), **graph_hash)
        instance_variable_hash.each do |k,v|
          graph.instance_variable_set("@#{k}", v)
        end
        graph
      end

      # Takes a Arango::Result and instantiates a Arango::Graph::Base object from it.
      # @param graph_result [Arango::Result]
      # @param properties_result [Arango::Result]
      # @return [Arango::Graph::Base]
      def from_results(graph_result, properties_result, database: nil)
        hash = {}.merge(graph_result.to_h)
        %i[cache_enabled globally_unique_id id key_options object_id wait_for_sync].each do |key|
          hash[key] = properties_result[key]
        end
        from_h(hash, database: database)
      end

      # Retrieves all graphs from the database.
      # @param exclude_system [Boolean] Optional, default true, exclude system graphs.
      # @param database [Arango::Database]
      # @return [Array<Arango::Graph::Base>]
      Arango.request_class_method(Arango::Graph::Base, :all) do |exclude_system: true, database: Arango.current_database|
        query = { excludeSystem: exclude_system }
        { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| from_h(c.to_h, database: database) }}}
      end

      # Get graph from the database.
      # @param name [String] The name of the graph.
      # @param database [Arango::Database]
      # @return [Arango::Database]
      Arango.multi_request_class_method(Arango::Graph::Base, :get) do |name, database: Arango.current_database|
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

      # Retrieves a list of all graphs.
      # @param exclude_system [Boolean] Optional, default true, exclude system graphs.
      # @param database [Arango::Database]
      # @return [Array<String>] List of graph names.
      Arango.request_class_method(Arango::Graph::Base, :list) do |exclude_system: true, database: Arango.current_database|
        query = { excludeSystem: exclude_system }
        { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| c[:name] }}}
      end

      # Removes a graph.
      # @param name [String] The name of the graph.
      # @param database [Arango::Database]
      # @return nil
      Arango.request_class_method(Arango::Graph::Base, :drop) do |name, database: Arango.current_database|
        { delete: "_api/collection/#{name}" , block: ->(_) { nil }}
      end
      alias delete drop
      alias destroy drop
      alias batch_delete batch_drop
      alias batch_destroy batch_drop

      # Check if graph exists.
      # @param name [String] Name of the graph
      # @param database [Arango::Database]
      # @return [Boolean]
      Arango.request_class_method(Arango::Graph::Base, :exist?) do |name, exclude_system: true, database: Arango.current_database|
        query = { excludeSystem: exclude_system }
        { get: '_api/collection', query: query, block: ->(result) { result.result.map { |c| c[:name] }.include?(name) }}
      end

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
    end
  end
end
