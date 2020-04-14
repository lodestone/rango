module Arango
  module Graph
    module ClassMethods
      def from_h(graph_hash, database: Arango.current_database)
        graph_hash = graph_hash.transform_keys { |k| k.to_s.underscore.to_sym }
        graph_hash.merge!(database: database) unless graph_hash.key?(:database)
        if graph_hash.key?(:properties)
          graph_hash[:name] = graph_hash[:properties].delete(:name) if graph_hash[:properties].key?(:name)
        end
        Arango::Graph::Base.new(**graph_hash)
      end

      # Takes a Arango::Result and instantiates a Arango::Graph::Base object from it.
      # @param graph_result [Arango::Result]
      # @param properties_result [Arango::Result]
      # @return [Arango::Graph::Base]
      def from_results(graph_result, properties_result, database: Arango.current_database)
        hash = graph_result ? {}.merge(graph_result.to_h) : {}
        hash[:properties] = properties_result
        from_h(hash, database: database)
      end

      def self.extended(base)
        # Retrieves all graphs from the database.
        # @param exclude_system [Boolean] Optional, default true, exclude system graphs.
        # @param database [Arango::Database]
        # @return [Array<Arango::Graph::Base>]
        Arango.request_class_method(base, :all) do |database: Arango.current_database|
          { get: '_api/gharial', block: ->(result) { result.graphs.map { |c| from_results({}, c.to_h, database: database) }}}
        end

        # Get graph from the database.
        # @param name [String] The name of the graph.
        # @param database [Arango::Database]
        # @return [Arango::Database]
        Arango.request_class_method(base, :get) do |name:, database: Arango.current_database|
          { get: "/_api/gharial/#{name}", block: ->(result) { from_results({}, result.graph, database: database) }}
        end
        base.singleton_class.alias_method :fetch, :get
        base.singleton_class.alias_method :retrieve, :get
        base.singleton_class.alias_method :batch_fetch, :batch_get
        base.singleton_class.alias_method :batch_retrieve, :batch_get

        # Retrieves a list of all graphs.
        # @param exclude_system [Boolean] Optional, default true, exclude system graphs.
        # @param database [Arango::Database]
        # @return [Array<String>] List of graph names.
        Arango.request_class_method(base, :list) do |database: Arango.current_database|
          { get: '_api/gharial', block: ->(result) { result.graphs.map { |c| c[:name] }}}
        end

        # Removes a graph.
        # @param name [String] The name of the graph.
        # @param database [Arango::Database]
        # @return nil
        Arango.request_class_method(base, :drop) do |name:, database: Arango.current_database|
          { delete: "_api/gharial/#{name}" , block: ->(_) { nil }}
        end
        base.singleton_class.alias_method :delete, :drop
        base.singleton_class.alias_method :destroy, :drop
        base.singleton_class.alias_method :batch_delete, :batch_drop
        base.singleton_class.alias_method :batch_destroy, :batch_drop

        # Check if graph exists.
        # @param name [String] Name of the graph
        # @param database [Arango::Database]
        # @return [Boolean]
        Arango.request_class_method(base, :exists?) do |name:, database: Arango.current_database|
          { get: '_api/gharial', block: ->(result) { result.graphs.map { |c| c[:name] }.include?(name) }}
        end
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
