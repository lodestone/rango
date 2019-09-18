# === COLLECTION ===

module Arango
  class Collection
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::DatabaseAssignment

    include Arango::Collection::Documents
    include Arango::Collection::Indexes

    STATES = %i[unknown new_born unloaded loaded being_unloaded deleted loading] # do not sort, index is used
    TYPES = %i[unknown unknown document edge] # do not sort, index is used

    class << self
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
      def all(exclude_system: true, database:)
        query = { excludeSystem: exclude_system }
        result = database.request("GET", "_api/collection", query: query, key: :result)
        result.map { |c| from_h(c.to_h, database: database) }
      end

      # Get collection from the database.
      # @param name [String] The name of the collection.
      # @param database [Arango::Database]
      # @return [Arango::Database]
      def get(name, database:)
        batch = Arango::RequestBatch.new(database: database)
        batch.add_request('collection', "GET", "/_api/collection/#{name}")
        batch.add_request('collection_properties', "GET", "/_api/collection/#{name}/properties")
        result = batch.execute
        from_results(result[:collection], result[:collection_properties], database: database)
      end
      alias fetch get
      alias retrieve get

      # Retrieves a list of all collections.
      # @param exclude_system [Boolean] Optional, default true, exclude system collections.
      # @param database [Arango::Database]
      # @return [Array<String>] List of collection names.
      def list(exclude_system: true, database:)
        query = { excludeSystem: exclude_system }
        result = database.request("GET", "_api/collection", query: query, key: :result)
        result.map { |c| c[:name] }
      end

      # Removes a collection.
      # @param name [String] The name of the collection.
      # @param database [Arango::Database]
      # @return nil
      def drop(name, database:)
        database.request("DELETE", "_api/collection/#{name}")
        nil
      end
      alias delete drop
      alias destroy drop

      # Check if collection exists.
      # @param name [String] Name of the collection
      # @param database [Arango::Database]
      # @return [Boolean]
      def exist?(name, exclude_system: true, database:)
        result = list(exclude_system: exclude_system, database: database)
        result.include?(name)
      end
    end

    # Instantiate a new collection.
    # For param description see the attributes descriptions. All params except name and database are optional.
    # @param name [String] The name of the collection.
    # @param type [Symbol]
    # @param database [Arango::Database]
    # @param status
    # @param distribute_shards_like
    # @param do_compact
    # @param index_buckets
    # @param is_system
    # @param is_volatile
    # @param journal_size
    # @param key_options
    # @param number_of_shards
    # @param replication_factor
    # @param shard_keys
    # @param sharding_strategy
    # @param smart_join_attribute
    # @param wait_for_sync
    # @param wait_for_sync_replication
    # @param enforce_replication_factor
    # @return [Arango::Collection]
    def initialize(name, database:, graph: nil, type: :document,
                   status: nil,
                   distribute_shards_like: nil, do_compact: nil, enforce_replication_factor: nil, index_buckets: nil, is_system: false,
                   is_volatile: false, journal_size: nil, key_options: nil, number_of_shards: nil, replication_factor: nil, shard_keys: nil,
                   sharding_strategy: nil, smart_join_attribute: nil, wait_for_sync: nil, wait_for_sync_replication: nil)
      assign_database(database)
      #  assign_graph(graph)
      @aql = nil
      @batch_proc = nil
      @name = name
      @name_changed = false
      @original_name = name
      @distribute_shards_like = distribute_shards_like
      @do_compact = do_compact
      @enforce_replication_factor = enforce_replication_factor
      @index_buckets = index_buckets
      @is_system = is_system
      @is_volatile = is_volatile
      @journal_size = journal_size
      @journal_size_changed = false
      @key_options = key_options
      @number_of_shards = number_of_shards
      @replication_factor = replication_factor
      @shard_keys = shard_keys
      @sharding_strategy = sharding_strategy
      @smart_join_attribute = smart_join_attribute
      _set_status(status)
      _set_type(type)
      @wait_for_sync = wait_for_sync
      @wait_for_sync_changed = false
      @wait_for_sync_replication = wait_for_sync_replication
    end

    attr_reader :database, :graph, :server

    # @return [Boolean]
    attr_reader :cache_enabled

    # In an Enterprise Edition cluster, this attribute binds the specifics of sharding for the newly created collection to follow that of a specified
    # existing collection.
    # Note: Using this parameter has consequences for the prototype collection. It can no longer be dropped,
    # before the sharding-imitating collections are dropped. Equally, backups and restores of imitating collections alone will generate warnings
    # (which can be overridden) about missing sharding prototype.
    # (The default is ”“)
    # Can only be set by calling the constructor with the distribute_shards_like param.
    # @return [String]
    attr_reader :distribute_shards_like

    # Whether or not the collection will be compacted (default is true) This option is meaningful for the MMFiles storage engine only.
    # Can only be set by calling the constructor with the do_compact param.
    # @return [Boolean]
    attr_reader :do_compact

    # Default is 1 which means the server will check if there are enough replicas available at creation time and
    # bail out otherwise. Set to 0 to disable this extra check.
    # Can only be set by calling the constructor with the enforce_replication_factor param.
    # @return [Integer]
    attr_reader :enforce_replication_factor

    # @return [String]
    attr_reader :globally_unique_id

    # @return [String]
    attr_reader :id

    # The number of buckets into which indexes using a hash table are split. The default is 16 and this number
    # has to be a power of 2 and less than or equal to 1024.
    # This option is meaningful for the MMFiles storage engine only.
    # Can only be set by calling the constructor with the index_buckets param.
    # @return [Integer]
    attr_reader :index_buckets

    # If true, create a system collection. In this case collection-name should start with an underscore.
    # End users should normally create non-system collections only. API implementors may be required to create system collections in
    # very special occasions, but normally a regular collection will do. (The default is false)
    # Can only be set by calling the constructor with the is_system param.
    # @return [Boolean]
    attr_reader :is_system

    # If true then the collection data is kept in-memory only and not made persistent. Unloading the collection will cause the collection data to
    # be discarded. Stopping or re-starting the server will also cause full loss of data in the collection.
    # Setting this option will make the resulting collection be slightly faster than regular collections because ArangoDB does not enforce any
    # synchronization to disk and does not calculate any CRC checksums for datafiles (as there are no datafiles). This option should therefore
    # be used for cache-type collections only, and not for data that cannot be re-created otherwise. (The default is false)
    # This option is meaningful for the MMFiles storage engine only.
    # Can only be set by calling the constructor with the is_volatile param.
    # @return [Boolean]
    attr_reader :is_volatile

    # The maximal size of a journal or datafile in bytes. The value must be at least 1048576 (1 MiB). (The default is a configuration parameter).
    # This option is meaningful for the MMFiles storage engine only.
    # @return [Integer] or nil
    attr_reader :journal_size

    # The name of the collection.
    # @return [String]
    attr_reader :name

    # In a cluster, this value determines the number of shards to create for the collection. In a single server setup, this option is meaningless.
    # (The default is 1)
    # Can only be set by calling the constructor with the number_of_shards param.
    # @return [Integer]
    attr_reader :number_of_shards

    # In a cluster, this attribute determines how many copies of each shard are kept on different DBServers.
    # The value 1 means that only one copy (no synchronous replication) is kept.
    # A value of k means that k-1 replicas are kept. Any two copies reside on different DBServers.
    # Replication between them is synchronous, that is, every write operation to the “leader” copy will be replicated to all “follower” replicas,
    # before the write operation is reported successful.
    # (The default is 1)
    # Can only be set by calling the constructor with the replication_factor param.
    # @return [Integer]
    attr_reader :replication_factor

    # In a cluster, this attribute determines which document attributes are used to determine the target shard for documents.
    # Documents are sent to shards based on the values of their shard key attributes.
    # The values of all shard key attributes in a document are hashed, and the hash value is used to determine the target shard.
    # Note: Values of shard key attributes cannot be changed once set. This option is meaningless in a single server setup.
    # (The default is [ “_key” ])
    # Can only be set by calling the constructor with the shard_keys param.
    # @return [Array<String>]
    attr_reader :shard_keys

    # In an Enterprise Edition cluster, this attribute determines an attribute of the collection that must contain the shard key value of the
    # referred-to smart join collection. Additionally, the shard key for a document in this collection must contain the value of this attribute,
    # followed by a colon, followed by the actual primary key of the document.
    # This feature can only be used in the Enterprise Edition and requires the distributeShardsLike attribute of the collection to be set to the name
    # of another collection. It also requires the shardKeys attribute of the collection to be set to a single shard key attribute,
    # with an additional ‘:’ at the end. A further restriction is that whenever documents are stored or updated in the collection,
    # the value stored in the smartJoinAttribute must be a string.
    # Can only be set by calling the constructor with the smart_join_attribute param.
    # @return [String]
    attr_reader :smart_join_attribute

    # If true then the data is synchronized to disk before returning from a document create, update, replace or removal operation. (default: false)
    # @return [Boolean]
    attr_reader :wait_for_sync

    # Default is true which means the server will only report success back to the client if all replicas have created the collection.
    # Set to false if you want faster server responses and don’t care about full replication.
    # Can only be set by calling the constructor with the wait_for_sync_replication param.
    # @return [Boolean]
    attr_reader :wait_for_sync_replication

    # The collections ArangoDB object_id, not to be confused with the collections ruby object_id.
    # @return [String]
    def arango_object_id
      @object_id
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
      Arango::Result.new(@key_options)
    end

    # This attribute specifies the name of the sharding strategy to use for the collection. Since ArangoDB 3.4 there are different sharding strategies
    # to select from when creating a new collection.
    # The selected shardingStrategy value will remain fixed for the collection and cannot be changed afterwards.
    # This is important to make the collection keep its sharding settings and always find documents already distributed to shards using the same
    # initial sharding algorithm.
    # The available sharding strategies are:
    # - community_compat: default sharding used by ArangoDB Community Edition before version 3.4
    # - enterprise_compat: default sharding used by ArangoDB Enterprise Edition before version 3.4
    # - enterprise_smart_edge_compat: default sharding used by smart edge collections in ArangoDB Enterprise Edition before version 3.4
    # - hash: default sharding used for new collections starting from version 3.4 (excluding smart edge collections)
    # - enterprise_hash_smart_edge: default sharding used for new smart edge collections starting from version 3.4
    # If no sharding strategy is specified, the default will be hash for all collections, and enterprise_hash_smart_edge for all smart edge
    # collections (requires the Enterprise Edition of ArangoDB). Manually overriding the sharding strategy does not yet provide a benefit,
    # but it may later in case other sharding strategies are added.
    # Can only be set by calling the constructor with the sharding_strategy param and is only available when creating the collection.
    # Usually its just nil.
    # @return [Symbol, NilClass]
    def sharding_strategy
      @sharding_strategy.to_s.underscore.to_sym if @sharding_strategy
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
      @journal_size = n
    end

    def name=(n)
      @name_changed = true
      @name = n
    end

    def wait_for_sync=(boolean)
      @wait_for_sync_changed = true
      @wait_for_sync = boolean
    end

    # Stores the collection in the database.
    # @return [Arango::Collection] self
    def create
      @name_changed = false
      @journal_size_changed = false
      @wait_for_sync_changed = false

      body = {}
      %i[distributeShardsLike doCompact indexBuckets isSystem isVolatile journalSize name numberOfShards replicationFactor shardingStrategy shardKeys
      smartJoinAttribute type waitForSync].each do |key|
        body[key] = instance_variable_get("@#{key.to_s.underscore}")
      end

      if @key_options && @key_options.class == Hash
        key_options_hash = @key_options.transform_keys { |key| key.to_s.camelize(:lower).to_sym }
        key_options_hash.delete_if{|_,v| v.nil?}
        body[:keyOptions] = key_options_hash unless key_options_hash.empty?
      end

      if @enforce_replication_factor || @wait_for_sync_replication
        query = {}
        query[:enforceReplicationFactor] = @enforce_replication_factor unless @enforce_replication_factor.nil?
        query[:waitForSyncReplication] = @wait_for_sync_replication unless @wait_for_sync_replication.nil?
        result = @database.request("POST", "_api/collection", body: body, query: query)
        _update_attributes(result)
      else
        result = @database.request("POST", "_api/collection", body: body)
        _update_attributes(result)
      end
      self
    end

    # Drops a collection.
    # @return [NilClass]
    def drop
      @database.request("DELETE", "_api/collection/#{@name}", query: { isSystem: @is_system })
      nil
    end

    # Truncates a collection.
    # @return [Arango::Collection] self
    def truncate
      @database.request("PUT", "_api/collection/#{@name}/truncate")
      self
    end

    # Counts the documents in a collection
    # @return [Integer]
    def size
      @database.request("GET", "_api/collection/#{@name}/count", key: :count)
    end
    alias count size
    alias length size

    # Fetch the statistics of a collection
    # @return [Hash]
    def statistics
      @database.request("GET", "_api/collection/#{@name}/figures", key: :figures)
    end

    # Return the shard ids of a collection
    # Note: This method only works on a cluster coordinator.
    # @param details [Boolean] If set to true, the return value will also contain the responsible servers for the collections’ shards.
    # @return [Array, Hash]
    def shards(details: false)
      @database.request("GET", "_api/collection/#{@name}/shards", key: :shards, query: { details: details }) if @server.coordinator?
    end

    # Retrieve the collections revision id
    # @return [String]
    def revision
      @database.request("GET", "_api/collection/#{@name}/revision", key: :revision)
    end

    # Returns a checksum for the specified collection
    # @param with_revisions [Boolean] Whether or not to include document revision ids in the checksum calculation, optional, default: false.
    # @param with_data [Boolean] Whether or not to include document body data in the checksum calculation, optional, default: false.
    def checksum(with_revisions: false, with_data: false)
      query = {
        withRevisions: with_revisions,
        withData: with_data
      }
      @database.request("GET", "_api/collection/#{@name}/checksum", query: query, key: :checksum)
    end

    # Loads a collection into ArangoDBs memory. Returns the collection on success.
    # @return [Arango::Collection] self
    def load_into_memory
      result = @database.request("PUT", "_api/collection/#{@name}/load", body: { count: false }, key: :status)
      _set_status(result)
      self
    end

    # Unloads a collection into ArangoDBs memory. Returns the collection on success.
    # @return [Arango::Collection] self
    def unload_from_memory
      result = @database.request("PUT", "_api/collection/#{@name}/unload", key: :status)
      _set_status(result)
      self
    end

    # Load Indexes into Memory
    # Note: For the time being this function is only useful on RocksDB storage engine, as in MMFiles engine all indexes are in memory anyways.
    # @return [Arango::Collection] self
    def load_indexes_into_memory
      @database.request("PUT", "_api/collection/#{@name}/loadIndexesIntoMemory") if @server.rocksdb?
      self
    end

    # Rotates the journal of a collection. Collection must have a journal.
    # Note: This method is specific for the MMFiles storage engine, and there it is not available in a cluster.
    # @return [Arango::Collection] self
    def rotate_journal
      @database.request("PUT", "_api/collection/#{@name}/rotate") if @server.mmfiles?
      self
    end

    # recalculates the document count of a collection
    # Note: This function is only useful on RocksDB storage engine.
    # @return [Arango::Collection] self
    def recalculate_count
      @database.request("PUT", "_api/collection/#{@name}/recalculateCount") if @server.rocksdb?
      size
    end

    # Reload collection properties and name from the database, reverting any changes.
    # @return [Arango::Collection] self
    def reload
      request_name = @name_changed ? @original_name : @name
      @name_changed = false
      @journal_size_changed = false
      @wait_for_sync_changed = false
      result = @database.request("GET", "_api/collection/#{request_name}/properties")
      _update_attributes(result)
      self
    end
    alias refresh reload
    alias retrieve reload
    alias revert reload

    # Save changed collection properties and name changed, to the database.
    # Note: except for wait_for_sync, journal_size and name, collection properties cannot be changed once a collection is created.
    # @return [Arango::Collection] self
    def save
      if @name_changed
        request_name = @name_changed ? @original_name : @name
        @name_changed = false
        @database.request("PUT", "_api/collection/#{request_name}/rename", body: { name: @name })
        @original_name = @name
      end
      if @journal_size_changed || @wait_for_sync_changed
        body = {}
        body[:journalSize] = @journal_size if @journal_size_changed && @server.mmfiles?
        body[:waitForSync] = @wait_for_sync if @wait_for_sync_changed
        @journal_size_changed = false
        @wait_for_sync_changed = false
        result = @database.request("GET", "_api/collection/#{@name}/properties", body: body)
        @journal_size = result.journal_size if result.key?(:journal_size)
        @wait_for_sync = result.wait_for_sync if result.key?(:wait_for_sync)
      end
      self
    end
    alias update save

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
      %i[cacheEnabled globallyUniqueId id isSystem keyOptions name objectId status type waitForSync].each do |key|
        instance_variable_set("@#{key.to_s.underscore}", result[key]) if result.key?(key)
      end
    end
  end
end
