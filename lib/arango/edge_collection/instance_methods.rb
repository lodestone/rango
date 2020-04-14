module Arango
  module EdgeCollection
    module InstanceMethods
      extend Arango::Helper::RequestMethod

      # Instantiate a new collection.
      # For param description see the attributes descriptions. All params except name and database are optional.
      # @param name [String] The name of the collection.
      # @param type [Symbol]
      # @param database [Arango::Database]
      # @param status
      # @return [Arango::DocumentCollection]
      def initialize(database: Arango.current_database, graph: nil,
                     name:, id: nil, is_system: false, status: nil, type: :edge,
                     properties: {})
        send(:database=, database) if database
        send(:graph=, graph) if graph
        @aql = nil
        @batch_proc = nil
        @id = id
        @is_system = is_system
        _set_name(name)
        @name_changed = false
        @original_name = name

        _set_status(status)
        _set_type(type)
        _set_properties(properties)
      end

      attr_accessor :database
      attr_reader :graph

      def method_missing(property, *args, &block)
        property_s = property.to_s.underscore
        property_y = property_s.to_sym
        return @properties[property_y] = args[0] if property_s.end_with?('=')
        return @properties[property_y] if @properties.key?(property_y)
        super(property, *args, &block)
      end

      # @return [String]
      attr_reader :id

      # If true, create a system collection. In this case collection-name should start with an underscore.
      # End users should normally create non-system collections only. API implementors may be required to create system collections in
      # very special occasions, but normally a regular collection will do. (The default is false)
      # Can only be set by calling the constructor with the is_system param.
      # @return [Boolean]
      attr_reader :is_system

      # The name of the collection.
      # @return [String]
      attr_reader :name

      # The collections ArangoDB object_id, not to be confused with the collections ruby object_id.
      # @return [String]
      def arango_object_id
        @properties[:object_id]
      end

      # Additional options for key generation. If specified, then key_options should be a Hash containing the following attributes:
      # - type: specifies the type of the key generator. The currently available generators are traditional, autoincrement, uuid and padded.
      # - allow_user_keys: if set to true, then it is allowed to supply own key values in the _key attribute of a document.
      #   If set to false, then the key generator will solely be responsible for generating keys and supplying own key values in the _key attribute
      #   of documents is considered an error.
      # - increment: increment value for autoincrement key generator. Not used for other key generator types.
      # - offset: Initial offset value for autoincrement key generator. Not used for other key generator types.
      # Can only be set by calling the constructor with the key_options param.
      # @return [Arango::Result]
      def key_options
        Arango::Result.new(@properties[:key_options])
      end

      # The status of the collection as symbol, one of:
      # - :unknown
      # - :new_born
      # - :unloaded
      # - :loaded
      # - :being_unloaded
      # - :deleted
      # - :loading
      # @return [Symbol]
      def status
        STATES[@status]
      end

      # The type of the collection to create. The following values for type are valid:
      #   - document collection, use the :document symbol
      #   - edge collection, use the :edge symbol
      # The default collection type is :document.
      # Can only be set by calling the constructor with the type param.
      # @return [Symbol]
      def type
        TYPES[@type]
      end

      def journal_size=(n)
        @journal_size_changed = true
        @properties[:journal_size] = n
      end

      def wait_for_sync=(n)
        @wait_for_sync_changed = true
        @properties[:wait_for_sync] = n
      end

      def name=(n)
        @name_changed = true
        _set_name(n)
      end

      def arango_server
        @database.arango_server
      end

      # Stores the collection in the database.
      # @return [Arango::DocumentCollection] self
      request_method :create do
        @name_changed = false
        @journal_size_changed = false
        @wait_for_sync_changed = false

        body = { name: @name, type: @type }

        @properties.each do |k, v|
          body[k.to_s.camelize(:lower)] = v unless v.nil?
        end

        if body[:keyOptions]
          body[:keyOptions].delete_if{|_,v| v.nil?}
          body[:keyOptions].transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
        end

        enforce_replication_factor = body.delete(:enforceReplicationFactor)
        wait_for_sync_replication = body.delete(:waitForSyncReplication)

        query = nil
        if enforce_replication_factor || wait_for_sync_replication
          query = {}
          query[:enforceReplicationFactor] = enforce_replication_factor unless enforce_replication_factor.nil?
          query[:waitForSyncReplication] = wait_for_sync_replication unless wait_for_sync_replication.nil?
        end

        { post: '_api/collection', body: body, query: query, block: ->(result) { _update_attributes(result); self }}
      end

      # Drops a collection.
      # @return [NilClass]
      request_method :drop do
        { delete: "_api/collection/#{@name}", query: { isSystem: @is_system }, block: ->(_) { nil }}
      end
      alias delete drop
      alias destroy drop
      alias batch_delete batch_drop
      alias batch_destroy batch_drop

      # Truncates a collection.
      # @return [Arango::DocumentCollection] self
      request_method :truncate do
        { put: "_api/collection/#{@name}/truncate", block: ->(_) { self }}
      end

      # Counts the documents in a collection
      # @return [Integer]
      request_method :size do
        { get: "_api/collection/#{@name}/count", block: ->(result) { result.count }}
      end
      alias count size
      alias length size
      alias batch_count batch_size
      alias batch_length batch_size

      # Fetch the statistics of a collection
      # @return [Hash]
      request_method :statistics do
        { get: "_api/collection/#{@name}/figures", block: ->(result) { Arango::Result.new(result.figures) }}
      end

      # Return the shard ids of a collection
      # Note: This method only works on a cluster coordinator.
      # @param details [Boolean] If set to true, the return value will also contain the responsible servers for the collections’ shards.
      # @return [Array, Hash]
      def shards(details: false)
        @database.request(get: "_api/collection/#{@name}/shards", query: { details: details }).shards if @database.arango_server.coordinator?
      end

      # Retrieve the collections revision id
      # @return [String]
      request_method :revision do
        { get: "_api/collection/#{@name}/revision", block: -> (result) { result.revision }}
      end

      # Returns a checksum for the specified collection
      # @param with_revisions [Boolean] Whether or not to include document revision ids in the checksum calculation, optional, default: false.
      # @param with_data [Boolean] Whether or not to include document body data in the checksum calculation, optional, default: false.
      request_method :checksum do |with_revisions: false, with_data: false|
        query = {
          withRevisions: with_revisions,
          withData: with_data
        }
        { get: "_api/collection/#{@name}/checksum", query: query, block: ->(result) { result.checksum } }
      end

      # Loads a collection into ArangoDBs memory. Returns the collection on success.
      # @return [Arango::DocumentCollection] self
      def load_into_memory
        result = @database.request(put: "_api/collection/#{@name}/load", body: { count: false }).status
        _set_status(result)
        self
      end

      # Unloads a collection into ArangoDBs memory. Returns the collection on success.
      # @return [Arango::DocumentCollection] self
      def unload_from_memory
        result = @database.request(put: "_api/collection/#{@name}/unload").status
        _set_status(result)
        self
      end

      # Load Indexes into Memory
      # Note: For the time being this function is only useful on RocksDB storage engine, as in MMFiles engine all indexes are in memory anyways.
      # @return [Arango::DocumentCollection] self
      def load_indexes_into_memory
        @database.request(put: "_api/collection/#{@name}/loadIndexesIntoMemory") if @database.arango_server.rocksdb?
        self
      end

      # Rotates the journal of a collection. Collection must have a journal.
      # Note: This method is specific for the MMFiles storage engine, and there it is not available in a cluster.
      # @return [Arango::DocumentCollection] self
      def rotate_journal
        @database.request(put: "_api/collection/#{@name}/rotate") if @database.arango_server.mmfiles?
        self
      end

      # recalculates the document count of a collection
      # Note: This function is only useful on RocksDB storage engine.
      # @return [Arango::DocumentCollection] self
      def recalculate_count
        @database.request(put: "_api/collection/#{@name}/recalculateCount") if @database.arango_server.rocksdb?
        self
      end

      # Reload collection properties and name from the database, reverting any changes.
      # @return [Arango::DocumentCollection] self
      request_method :reload do
        request_name = @name_changed ? @original_name : @name
        @name_changed = false
        @journal_size_changed = false
        @wait_for_sync_changed = false
        { get: "_api/collection/#{request_name}/properties", block: ->(result) { _update_attributes(result); self }}
      end
      alias refresh reload
      alias retrieve reload
      alias revert reload
      alias batch_refresh batch_reload
      alias batch_retrieve batch_reload
      alias batch_revert batch_reload

      # Save changed collection properties and name changed, to the database.
      # Note: except for wait_for_sync, journal_size and name, collection properties cannot be changed once a collection is created.
      # @return [Arango::DocumentCollection] self
      multi_request_method :save do
        requests = []
        if @name_changed
          request_name = @name_changed ? @original_name : @name
          @name_changed = false
          # @database.request(put: "_api/collection/#{request_name}/rename", body: { name: @name })
          requests << { put: "_api/collection/#{request_name}/rename", body: { name: @name }, block: -> (_) { self }}
          @original_name = @name
        end
        if @journal_size_changed || @wait_for_sync_changed
          body = {}
          body[:journalSize] = @journal_size if @journal_size_changed && @database.arango_server.mmfiles?
          body[:waitForSync] = @wait_for_sync if @wait_for_sync_changed
          @journal_size_changed = false
          @wait_for_sync_changed = false
          # result = @database.request(get: "_api/collection/#{@name}/properties", body: body)
          requests << { put: "_api/collection/#{@name}/properties", body: body, block: -> (result) {
            @journal_size = result.journal_size if result.key?(:journal_size)
            @wait_for_sync = result.wait_for_sync if result.key?(:wait_for_sync)
            self
          }}
        end
        requests
      end
      alias update save
      alias batch_update batch_save

      # Request next batch from a batched request.
      # @return value depending on original batched request.
      def next_batch
        return unless has_more?
        result = @aql.next
        final_result = if @batch_proc
                         @batch_proc.call(result)
                       else
                         result
                       end
        unless @aql.has_more?
          @aql = nil
          @batch_proc = nil
        end
        final_result
      end

      # Check if more results are available for a betched request.
      # @return [Boolean]
      def has_more?
        return false unless @aql
        @aql.has_more?
      end

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

      def _set_type(t)
        if t.class == Symbol && TYPES.include?(t)
          @type = TYPES.index(t)
          @type = 2 if @type < 2
        elsif t.class == Integer && t >= 2 && t <= 3
          @type = t
        else
          @type = 2
        end
      end

      def _update_attributes(result)
        hash = result.raw_result
        @id = hash.delete(:id)
        @is_system = hash.delete(:is_system)
        _set_name(hash.delete(:name))
        s = hash.delete(:status)
        _set_status(s) if s
        t = hash.delete(:type)
        _set_type(t) if t
        _set_properties(hash)
      end

      def _set_properties(properties)
        properties = if properties
                        properties.transform_keys! { |k| k.to_s.underscore.to_sym }
                        properties[:key_options].transform_keys! { |k| k.to_s.underscore.to_sym } if properties.key?(:key_options)
                        properties[:sharding_strategy].to_s.underscore.to_sym if properties.key?(:sharding_strategy)
                        properties
                      else
                        {}
                      end
        return @properties = properties unless @properties
        @properties.merge!(properties)
      end
    end
  end
end
