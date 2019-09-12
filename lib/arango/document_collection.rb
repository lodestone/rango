# === COLLECTION ===

module Arango
  class DocumentCollection
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::DatabaseAssignment

    include Arango::DocumentCollection::Basics
    include Arango::DocumentCollection::DocumentAccess
    include Arango::DocumentCollection::Indexes

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      database = hash[:database]
      if database.is_a?(Arango::Database) && database.server.active_cache
        cache_name = "#{database.name}/#{hash[:name]}"
        cached = database.server.cache.cache.dig(:database, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          body = hash[:body] || {}
          [:type, :isSystem].each{|k| body[k] ||= hash[k]}
          cached.assign_attributes(body)
          return cached
        end
      end
      super
    end

    def initialize(name:, database:, graph: nil, body: {}, type: :document,
      is_system: nil, cache_name: nil)
      @name = name
      assign_database(database)
      assign_graph(graph)
      assign_type(type)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:collection, cache_name, self)
      end
      body[:type]     ||= type == :document ? 2 : 3
      body[:status]   ||= nil
      body[:isSystem] ||= is_system
      body[:id]       ||= nil
      assign_attributes(body)
    end

# === DEFINE ===

    attr_reader :body, :cache_name, :count_export, :database, :graph, :has_more_export, :has_more_simple, :id, :id_export, :id_simple, :is_system,
                :server, :status, :type
    attr_accessor :name

    def graph=(graph)
      satisfy_class?(graph, [Arango::Graph, NilClass])
      if !graph.nil? && graph.database.name != @database.name
        raise Arango::Error.new err: :database_graph_no_same_as_collection_database,
        data: { graph_database_name: graph.database.name, collection_database_name:  @database.name}
      end
      @graph = graph
    end
    alias assign_graph graph=

    def body=(result)
      @body     = result
      @name     = result[:name] || @name
      @type     = assign_type(result[:type])
      @status   = reference_status(result[:status])
      @id       = result[:id] || @id
      @is_system = result[:isSystem] || @is_system
      if @server.active_cache && @cache_name.nil?
        @cache_name = "#{@database.name}/#{@name}"
        @server.cache.save(:database, @cache_name, self)
      end
    end
    alias assign_attributes body=

    def type=(type)
      type ||= @type
      satisfy_category?(type, ["Document", "Edge", 2, 3, nil, :document, :edge])
      @type = case type
      when 2, "Document", nil
        :document
      when 3, "Edge"
        :edge
      end
    end
    alias assign_type type=

    def reference_status(number)
      number ||= @number
      return nil if number.nil?
      hash = ["new born collection", "unloaded", "loaded",
        "in the process of being unloaded", "deleted", "loading"]
      return hash[number-1]
    end
    private :reference_status

# === TO HASH ===

    def to_h
      {
        name:     @name,
        type:     @type,
        status:   @status,
        id:       @id,
        isSystem: @is_system,
        body:     @body,
        cache_name: @cache_name,
        database: @database.name
      }.delete_if{|k,v| v.nil?}
    end

# === GET ===

    def retrieve
      result = @database.request("GET", "_api/collection/#{@name}")
      return_element(result)
    end


    def count
      @database.request("GET", "_api/collection/#{@name}/count", key: :count)
    end

    def statistics
      @database.request("GET", "_api/collection/#{@name}/figures", key: :figures)
    end

    def checksum(withRevisions: nil, withData: nil)
      query = {
        withRevisions: withRevisions,
        withData: withData
      }
      @database.request("GET", "_api/collection/#{@name}/checksum",  query: query,
        key: :checksum)
    end

# == POST ==

    def create(allow_user_keys: nil, distribute_shards_like: nil, do_compact: nil, increment_key_generator: nil, index_buckets: nil,
               is_system: @is_system, is_volatile: nil, journal_size: nil, number_of_shards: nil, offset_key_generator: nil, replication_factor: nil,
               shard_keys: nil, sharding_strategy: nil, type: @type, type_key_generator: nil, wait_for_sync: nil)
      satisfy_category?(type_key_generator, [nil, "traditional", "autoincrement"])
      satisfy_category?(type, ["Edge", "Document", 2, 3, nil, :edge, :document])
      satisfy_category?(sharding_strategy, [nil, "community-compat", "enterprise-compat", "enterprise-smart-edge-compat", "hash", "enterprise-hash-smart-edge"])
      keyOptions = {
        allowUserKeys:      allow_user_keys,
        type:               type_key_generator,
        increment:          increment_key_generator,
        offset:             offset_key_generator
      }
      keyOptions.delete_if{|k,v| v.nil?}
      keyOptions = nil if keyOptions.empty?
      type = case type
      when 2, "Document", nil, :document then 2
      when 3, "Edge", :edge then 3
      end
      body = {
        name: @name,
        type: type,
        distributeShardsLike: distribute_shards_like,
        doCompact:         do_compact,
        indexBuckets:      index_buckets,
        isSystem:          is_system,
        isVolatile:        is_volatile,
        journalSize:       journal_size,
        keyOptions:        keyOptions,
        numberOfShards:    number_of_shards,
        replicationFactor: replication_factor,
        shardingStrategy:  sharding_strategy,
        shardKeys:         shard_keys,
        waitForSync:       wait_for_sync
      }
      body = @body.merge(body)
      result = @database.request("POST", "_api/collection", body: body)
      return_element(result)
    end

# === MODIFY ===

    def load
      result = @database.request("PUT", "_api/collection/#{@name}/load")
      return_element(result)
    end

    def unload
      result = @database.request("PUT", "_api/collection/#{@name}/unload")
      return_element(result)
    end

    def load_indexes_into_memory
      if @server.engine[:name] == 'rocksdb'
        result = @database.request("PUT", "_api/collection/#{@name}/loadIndexesIntoMemory")
        return_element(result)
      else
        return true
      end
    end

    def change(wait_for_sync: nil, journal_size: nil)
      body = {
        journalSize: journal_size,
        waitForSync: wait_for_sync
      }
      result = @database.request("PUT", "_api/collection/#{@name}/properties", body: body)
      return_element(result)
    end


    def rotate
      if @server.engine[:name] == 'mmfiles'
        result = @database.request("PUT", "_api/collection/#{@name}/rotate")
        return_element(result)
      else
        return true
      end
    end

# == DOCUMENT ==

    def next
      if @has_more_simple
        result = @database.request("PUT", "_api/cursor/#{@id_simple}")
        @has_more_simple = result[:hasMore]
        @id_simple = result[:id]
        return result if return_directly?(result)
        return result[:result] unless @return_document
        if @return_document
          result[:result].map{|key| Arango::Document.new(name: key, collection: self)}
        end
      else
        raise Arango::Error.new err: :no_other_simple_next, data: {hasMoreSimple: @has_more_simple}
      end
    end

    def return_body(x, type=:document)
      satisfy_class?(x, [Hash, Arango::Document, Arango::Edge, Arango::Vertex])
      body = case x
      when Hash
        x
      when Arango::Edge
        if type == :vertex
          raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
            { expected_value: type, received_value: x.type, wrong_object: x }
        end
        x.body
      when Arango::Vertex
        if type == :edge
          raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
            { expected_value: type, received_value: x.type, wrong_object: x }
        end
        x.body
      when Arango::Document
        if (type == :vertex && x.collection.type == :edge)  ||
           (type == :edge && x.collection.type == :document) ||
           (type == :edge && x.collection.type == :vertex)
          raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
            { expected_value: type, received_value: x.collection.type, wrong_object: x}
        end
        x.body
      end
      return body.delete_if{|k,v| v.nil?}
    end
    private :return_body

    def return_id(x)
      satisfy_class?(x, [String, Arango::Document, Arango::Vertex])
      return x.is_a?(String) ? x : x.id
    end
    private :return_id



    def create_edges(document: {}, from:, to:, wait_for_sync: nil, return_new: nil, silent: nil)
      edges = []
      from = [from] unless from.is_a? Array
      to   = [to]   unless to.is_a? Array
      document = [document] unless document.is_a? Array
      document = document.map{|x| return_body(x, :edge)}
      from = from.map{|x| return_id(x)}
      to   = to.map{|x| return_id(x)}
      document.each do |b|
        from.each do |f|
          to.each do |t|
            b[:_from] = f
            b[:_to] = t
            edges << b.clone
          end
        end
      end
      create_documents(document: edges, wait_for_sync: wait_for_sync,
        return_new: return_new, silent: silent)
    end

    def all_documents(offset: 0, limit: nil, batch_size: nil)
      query = "FOR doc IN @name"
      query << "\n LIMIT @offset, @limit" if limit
      # TODO raise "offset must be used with limit" if offset > 0 && !limit # Arango::Error
      query << "\n RETURN doc"
      aql = Arango::AQL.new(database: @database, query: query, bind_vars: { '@name': @name, '@offset': offset, '@limit': limit })
      aql.size = batch_size if batch_size
      result = aql.execute
      result.result
    end

# == SIMPLE ==

    def generic_document_search(url, body, single=false)
      result = @database.request("PUT", url, body: body)
      @returnDocument = true
      @hasMoreSimple = result[:hasMore]
      @idSimple = result[:id]
      return result if return_directly?(result)

      if single
        Arango::Document.new(name: result[:document][:_key], collection: self,
          body: result[:document])
      else
        result[:result].map{|x| Arango::Document.new(name: x[:_key], collection: self, body: x)}
      end
    end
    private :generic_document_search

    def documents_match(match:, skip: nil, limit: nil, batch_size: nil)
      body = {
        collection: @name,
        example:    match,
        skip:       skip,
        limit:      limit,
        batchSize:  batch_size
      }
      generic_document_search("_api/simple/by-example", body)
    end

    def document_match(match:)
      body = {
        collection: @name,
        example:    match
      }
      generic_document_search("_api/simple/first-example", body, true)
    end

    def documents_by_keys(keys:)
      keys = [keys] unless keys.is_a?(Array)
      keys = keys.map{|x| x.is_a?(Arango::Document) ? x.name : x}
      query = "FOR doc IN @name FILTER doc._key IN @keys RETURN doc"
      aql = Arango::AQL.new(database: @database, query: query, bind_vars: { '@name': @name, '@keys': keys })
      result = aql.execute
      result.result
    end

    def random
      body = { collection:  @name }
      generic_document_search("_api/simple/any", body, true)
    end

    def remove_by_keys(keys:, return_old: nil, silent: nil, wait_for_sync: nil)
      options = {
        returnOld:   return_old,
        silent:      silent,
        waitForSync: wait_for_sync
      }
      options.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      if keys.is_a? Array
        keys = keys.map{|x| x.is_a?(String) ? x : x.key}
      end
      body = { collection: @name, keys: keys, options: options}
      result = @database.request("PUT", "_api/simple/remove-by-keys", body: body)
      return result if return_directly?(result)
      if return_old == true && silent != true
        result.each do |r|
          Arango::Document.new(name: r[:_key], collection: self, body: r)
        end
      else
        return result
      end
    end

    def remove_match(match:, limit: nil, wait_for_sync: nil)
      options = {
        limit:        limit,
        waitForSync:  wait_for_sync
      }
      options.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        collection:  @name,
        "example"    => match,
        "options"    => options
      }
      @database.request("PUT", "_api/simple/remove-by-example", body: body, key: :deleted)
    end

    def replace_match(match:, newValue:, limit: nil, wait_for_sync: nil)
      options = {
        limit:        limit,
        waitForSync:  wait_for_sync
      }
      options.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        collection: @name,
        example:    match,
        options:    options,
        newValue:   newValue
      }
      @database.request("PUT", "_api/simple/replace-by-example", body: body, key: :replaced)
    end

    def update_match(match:, newValue:, keep_null: nil, merge_objects: nil,
      limit: nil, wait_for_sync: nil)
      options = {
        keepNull:     keep_null,
        mergeObjects: merge_objects,
        limit:        limit,
        waitForSync:  wait_for_sync
      }
      options.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        collection: @name,
        example:    match,
        options:    options,
        newValue:   newValue
      }
      @database.request("PUT", "_api/simple/update-by-example", body: body, key: :updated)
    end

# === SIMPLE DEPRECATED ===

    def range(right:, attribute:, limit: nil, closed: true, skip: nil, left:,
      warning: @server.warning)
      warning_deprecated(warning, "range")
      body = {
        right:      right,
        attribute:  attribute,
        collection: @name,
        limit:  limit,
        closed: closed,
        skip:   skip,
        left:   left
      }
      result = @database.request("PUT", "_api/simple/range", body: body)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
      end
    end

    def distance(longitude:, latitude:, limit: nil, offset: 0)
      query = <<~QUERY
        FOR doc IN @name
         SORT DISTANCE(doc.latitude, doc.longitude, @latitude, @longitude) ASC
      QUERY
      query << "\n LIMIT @offset, @limit" if limit
      query << "\n RETURN doc"
      aql = Arango::AQL.new(database: @database, query: query, bind_vars: { '@name': @name, '@latitude': latitude, '@longitude': longitude,
                                                                            '@offset': offset, '@limit': limit})
      result = aql.execute
      result.result
    end

    def within(distance: nil, longitude:, latitude:, radius:, geo: nil,
      limit: nil, skip: nil, warning: @server.warning)
      warning_deprecated(warning, "within")
      body = {
        distance:   distance,
        longitude:  longitude,
        collection: @name,
        limit:      limit,
        latitude:   latitude,
        skip:       skip,
        geo:        geo,
        radius:     radius
      }
      result = @database.request("PUT", "_api/simple/within", body: body)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
      end
    end

    def within_rectangle(longitude1:, latitude1:, longitude2:, latitude2:,
      geo: nil, limit: nil, skip: nil, warning: @server.warning)
      warning_deprecated(warning, "withinRectangle")
      body = {
        "longitude1": longitude1,
        "latitude1":  latitude1,
        "longitude2": longitude2,
        "latitude2":  latitude2,
        collection: @name,
        limit:      limit,
        skip:       skip,
        geo:        geo,
      }
      result = @database.request("PUT", "_api/simple/within-rectangle", body: body)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
      end
    end

    def fulltext(attribute:, query:, limit: 0)
      query = "FOR doc IN FULLTEXT(@name, @attribute, @query, @limit) RETURN doc"
      aql = Arango::AQL.new(database: @database, query: query, bind_vars: { '@name': @name, '@attribute': attribute, '@query': query,
                                                                            '@limit': limit })
      result = aql.execute
      result.result
    end

  # === EXPORT ===

    def export(count: nil, restrict: nil, batch_size: nil,
      flush: nil, flush_wait: nil, limit: nil, ttl: nil)
      query = { collection:  @name }
      body = {
        count:     count,
        restrict:  restrict,
        batchSize: batch_size,
        flush:     flush,
        flushWait: flush_wait,
        limit:     limit,
        ttl:       ttl
      }
      result = @database.request("POST", "_api/export", body: body, query: query)
      return reuslt if @server.async != false
      @countExport   = result[:count]
      @hasMoreExport = result[:hasMore]
      @idExport      = result[:id]
      if return_directly?(result) || result[:result][0].nil? || !result[:result][0].is_a?(Hash) || !result[:result][0].key?(:_key)
        return result[:result]
      else
        return result[:result].map do |x|
          Arango::Document.new(name: x[:_key], collection: self, body: x)
        end
      end
    end

    def export_next
      unless @hasMoreExport
        raise Arango::Error.new err: :no_other_export_next, data: {hasMoreExport:  @hasMoreExport}
      else
        query = { collection:  @name }
        result = @database.request("PUT", "_api/export/#{@idExport}", query: query)
        return result if @server.async != false
        @countExport   = result[:count]
        @hasMoreExport = result[:hasMore]
        @idExport      = result[:id]
        if return_directly?(result) || result[:result][0].nil? || !result[:result][0].is_a?(Hash) || !result[:result][0].key?(:_key)
          return result[:result]
        else
          return result[:result].map do |x|
            Arango::Document.new(name: x[:_key], collection: self, body: x)
          end
        end
      end
    end





# === USER ACCESS ===

    def check_user(user)
      user = Arango::User.new(user: user) if user.is_a?(String)
      return user
    end
    private :check_user

    def add_user_access(grant:, user:)
      user = check_user(user)
      user.add_collection_access(grant: grant, database: @database.name, collection: @name)
    end

    def revoke_user_access(user:)
      user = check_user(user)
      user.clear_collection_access(database: @database.name, collection: @name)
    end

    def user_access(user:)
      user = check_user(user)
      user.collection_access(database: @database.name, collection: @name)
    end

# === GRAPH ===

    def vertex(name: nil, body: {}, rev: nil, from: nil, to: nil)
      if @type == :edge
        raise Arango::Error.new err: :is_a_edge_collection, data: {type:  @type}
      end
      if @graph.nil?
        Arango::Document.new(name: name, body: body, rev: rev, collection: self)
      else
        Arango::Vertex.new(name: name, body: body, rev: rev, collection: self)
      end
    end

    def edge(name: nil, body: {}, rev: nil, from: nil, to: nil)
      if @type == :document
        raise Arango::Error.new err: :is_a_document_collection, data: {type:  @type}
      end
      if @graph.nil?
        Arango::Document.new(name: name, body: body, rev: rev, collection: self)
      else
        Arango::Edge.new(name: name, body: body, rev: rev, from: from, to: to,
          collection: self)
      end
    end
  end
end
