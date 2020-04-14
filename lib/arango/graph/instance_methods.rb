module Arango
  module Graph
    module InstanceMethods
      extend Arango::Helper::RequestMethod

      # Instantiate a new collection.
      # For param description see the attributes descriptions. All params except name and database are optional.
      # @param name [String] The name of the collection.
      # @param database [Arango::Database]
      # @param status
      # @return [Arango::Graph]
      def initialize(database: Arango.current_database,
                     name:, id: nil, edge_definitions: [], orphan_collections: [], is_smart: false,
                     properties: {})
        @attributes = { name: name, id: id, edge_definitions: edge_definitions, orphan_collections: orphan_collections }
        @changed_attributes = {}
        send(:database=, database)
        @aql = nil
        @batch_proc = nil
        _set_name(name)
        @name_changed = false
        @original_name = name
        @edge_definitions = edge_definitions
        @orphan_collections = []
        _set_properties(properties)
      end

      attr_accessor :database

      def id
        @changed_attributes[:_id] || @attributes[:_id]
      end

      def id=(i)
        @changed_attributes[:_id] = i
      end

      def name
        @changed_attributes[:name] || @attributes[:name]
      end

      def name=(n)
        @name_changed = true
        _set_name(n)
      end

      def revision
        @changed_attributes[:_rev] || @attributes[:_rev]
      end

      def revision=(r)
        @changed_attributes[:_rev] = r
      end

      def to_h
        @attributes.delete_if{|_,v| v.nil?}
      end

      def wait_for_sync=(n)
        @wait_for_sync_changed = true
        @properties[:wait_for_sync] = n
      end

      # Stores the graph in the database.
      # @return [Arango::DocumentCollection] self
      request_method :create do
        @name_changed = false
        @wait_for_sync_changed = false

        body = {}.merge(@attributes)
        body.merge!(@changed_attributes)

        @properties.each do |k, v|
          body[:options][k.to_s.camelize(:lower)] = v unless v.nil?
        end

        query = nil
        if @wait_for_sync_changed
          query[:waitForSync] = @wait_for_sync
        end

        { post: '_api/gharial', body: body, query: query, block: ->(result) { _update_attributes(result[:graph]); self }}
      end

      # Drops a graph.
      # @return [NilClass]
      request_method :drop do
        { delete: "_api/gharial/#{@name}" , block: ->(_) { nil }}
      end
      alias delete drop
      alias destroy drop
      alias batch_delete batch_drop
      alias batch_destroy batch_drop

      private

      def _set_name(name)
        raise 'illegal_name' if name.include?('/') || name.include?('.')
        @name = name
      end

      def _set_status(s)
        if s.class == Symbol && STATES.include?(s)
          @status = STATES.index(s)
        elsif s.class == Integer && s >= 0 && s <= 6
          @status = s
        else
          @status = STATES[0]
        end
      end

      def _update_attributes(result)
        hash = result
        @id = hash.delete(:id)
        _set_name(hash.delete(:name))
        _set_properties(hash)
      end

      def _set_properties(properties)
        properties = if properties
                       properties.transform_keys! { |k| k.to_s.underscore.to_sym }
                       properties
                     else
                       {}
                     end
        return @properties = properties unless @properties
        @properties.merge!(properties)
      end

      # === GRAPH ===

      module Arango
        module Graph
          module Old
            #include Arango::Helper::Satisfaction

            #include Arango::Helper::DatabaseAssignment

          def initialize(name:, database:, body: {}, cache_name: nil, edge_definitions: [], is_smart: nil, number_of_shards: nil, orphan_collections: [],
                         replication_factor: nil, smart_graph_attribute: nil)
            assign_database(database)
            unless cache_name.nil?
              @cache_name = cache_name
              @server.cache.save(:graph, cache_name, self)
            end
            body[:_key]    ||= name
            body[:_id]     ||= "_graphs/#{name}"
            body[:edgeDefinitions]     ||= edge_definitions
            body[:isSmart]             ||= is_smart
            body[:numberOfShards]      ||= number_of_shards
            body[:orphanCollections]   ||= orphan_collections
            body[:replicationFactor]   ||= replication_factor
            body[:smartGraphAttribute] ||= smart_graph_attribute
            assign_attributes(body)
          end

# === DEFINE ===

          attr_reader :body, :cache_name, :database, :id, :is_smart, :name, :rev, :server
          attr_accessor :number_of_shards, :replication_factor, :smart_graph_attribute
          alias key name

          def body=(result)
            @body = result
            assign_edge_definitions(result[:edgeDefinitions] || @edge_definitions)
            assign_orphan_collections(result[:orphanCollections] || @orphan_collections)
            @name    = result[:_key]    || @name
            @id      = result[:_id]     || @id
            @id      = "_graphs/#{@name}" if @id.nil? && !@name.nil?
            @rev     = result[:_rev]    || @rev
            @is_smart = result[:isSmart] || @is_smart
            @number_of_shards = result[:numberOfShards] || @number_of_shards
            @replication_factor = result[:replicationFactor] || @replication_factor
            @smart_graph_attribute = result[:smartGraphAttribute] || @smart_graph_attribute
            if @server.active_cache && @cache_name.nil?
              @cache_name = "#{@database.name}/#{@name}"
              @server.cache.save(:graph, @cache_name, self)
            end
          end
          alias assign_attributes body=

          def name=(name)
            @name = name
            @id = "_graphs/#{@name}"
          end

          def return_collection(collection, type=nil)
            satisfy_class_or_string?(collection, Arango::DocumentCollection)
            case collection
            when Arango::DocumentCollection
              return collection
            when String
              return Arango::DocumentCollection.new(name:     collection,
                                                    database: @database, type: type, graph: self)
            end
          end

          def edge_definitions_raw
            @edge_definitions ||= []
            @edge_definitions.map do |edgedef|
              {
                collection: edgedef[:collection].name,
                from: edgedef[:from].map{|t| t.name},
                to: edgedef[:to].map{|t| t.name}
              }
            end
          end
          private :edge_definitions_raw

          def edge_definitions(raw=false)
            return edge_definitions_raw if raw
            return @edge_definitions
          end

          def edge_definitions=(edge_definitions)
            @edge_definitions = []
            edge_definitions ||= []
            edge_definitions = [edge_definitions] unless edge_definitions.is_a?(Array)
            edge_definitions.each do |edge_definition|
              hash = {}
              hash[:collection] = return_collection(edge_definition[:collection], :edge)
              edge_definition[:from] ||= []
              edge_definition[:to]   ||= []
              hash[:from] = edge_definition[:from].map{|t| return_collection(t)}
              hash[:to]   = edge_definition[:to].map{|t| return_collection(t)}
              setup_orphan_collection_after_adding_edge_definitions(hash)
              @edge_definitions << hash
            end
          end
          alias assign_edge_definitions edge_definitions=

          def orphan_collections=(orphan_collections)
            orphan_collections ||= []
            orphan_collections = [orphan_collections] unless orphan_collections.is_a?(Array)
            @orphan_collections = orphan_collections.map{|oc| add_orphan_collection(oc)}
          end
          alias assign_orphan_collections orphan_collections=

          def orphan_collections_raw
            @orphan_collections ||= []
            @orphan_collections.map{|oc| oc.name}
          end
          private :orphan_collections_raw

          def orphan_collections(raw=false)
            return orphan_collections_raw if raw
            return @orphan_collections
          end

# === HANDLE ORPHAN COLLECTION ===

          def add_orphan_collection(orphanCollection)
            orphanCollection = return_collection(orphanCollection)
            if @edge_definitions.any? do |ed|
              names = []
              names |= ed[:from].map{|f| f&.name}
              names |= ed[:to].map{|t| t&.name}
              names.include?(orphanCollection.name)
            end
              raise Arango::Error.new err: :orphan_collection_used_by_edge_definition, data: {collection: orphanCollection.name}
            end
            return orphanCollection
          end
          private :add_orphan_collection

          def setup_orphan_collection_after_adding_edge_definitions(edge_definition)
            collection = []
            collection |= edge_definition[:from]
            collection |= edge_definition[:to]
            @orphan_collections.delete_if{|c| collection.include?(c.name)}
          end
          private :setup_orphan_collection_after_adding_edge_definitions

          def setup_orphan_collection_after_removing_edge_definitions(edge_definition)
            edgeCollection = edge_definition[:collection].name
            collections |= []
            collections |= edge_definition[:from]
            collections |= edge_definition[:to]
            collections.each do |collection|
              unless @edge_definitions.any? do |ed|
                if ed[:collection].name != edgeCollection
                  names = []
                  names |= ed[:from].map{|f| f&.name}
                  names |= ed[:to].map{|t| t&.name}
                  names.include?(collection.name)
                else
                  false
                end
              end
                unless @orphan_collections.map{|oc| oc.name}.include?(collection.name)
                  @orphan_collections << collection
                end
              end
            end
          end
          private :setup_orphan_collection_after_removing_edge_definitions

# === REQUEST ===

          def request(action, url, body: {}, headers: {}, query: {}, key: nil, return_direct_result: false)
            url = "_api/gharial/#{@name}/#{url}"
            @database.request(action, url, body: body, headers: headers,
                              query: query, key: key, return_direct_result: return_direct_result)
          end

# === TO HASH ===

          def to_h
            {
              name: @name,
              id: @id,
              rev: @rev,
              isSmart: @is_smart,
              numberOfShards: @number_of_shards,
              replicationFactor: @replication_factor,
              smartGraphAttribute: @smart_graph_attribute,
              edgeDefinitions: edge_definitions_raw,
              orphanCollections: orphan_collections_raw,
              cache_name: @cache_name,
              database: @database.name
            }.delete_if{|k,v| v.nil?}
          end

# === GET ===

          def retrieve
            result = @database.request("GET", "_api/gharial/#{@name}", key: :graph)
            return_element(result)
          end

          end
        end
      end

      end
  end
end
