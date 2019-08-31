# === DATABASE ===

module Arango
  class Database
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::ServerAssignment

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      server = hash[:server]
      if server.is_a?(Arango::Server) && server.active_cache
        cache_name = hash[:name]
        cached = server.cache.cache.dig(:database, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          return cached
        end
      end
      super
    end

    def initialize(name:, server:, cache_name: nil)
      assign_server(server)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:database, cache_name, self)
      end
      @name = name
      @server = server
      @is_system = nil
      @path = nil
      @id = nil
    end

# === DEFINE ===

    attr_reader :is_system, :path, :id, :server, :cache_name
    attr_accessor :name

# === TO HASH ===

    def to_h
      {
        name:     @name,
        isSystem: @is_system,
        path:     @path,
        id:       @id,
        cache_name: @cache_name,
        server: @server.base_uri
      }.delete_if{|k,v| v.nil?}
    end

# === REQUEST ===

    def request(action, url, body: {}, headers: {},
      query: {}, key: nil, return_direct_result: false,
      skip_to_json: false, keep_null: false)
      url = "_db/#{@name}/#{url}"
      @server.request(action, url, body: body, headers: headers, query: query, key: key, return_direct_result: return_direct_result,
                      skip_to_json: skip_to_json, keep_null: keep_null)
    end

# === GET ===

    def assign_attributes(result)
      return unless result.is_a?(Hash)
      @id        = result[:id]
      @is_system = result[:isSystem]
      @name      = result[:name]
      @path      = result[:path]
      if @server.active_cache && @cache_name.nil?
        @cache_name = result[:name]
        @server.cache.save(:database, @cache_name, self)
      end
    end

    def retrieve
      result = request("GET", "_api/database/current", key: :result)
      assign_attributes(result)
      return return_directly?(result) ? result : self
    end
    alias current retrieve

# === POST ===

    def create(name: @name, users: nil)
      body = {
        name:  name,
        users: users
      }
      result = @server.request("POST", "_api/database", body: body, key: :result)
      return return_directly?(result) ? result : self
    end

# == DELETE ==

    def destroy
      @server.request("DELETE", "_api/database/#{@name}", key: :result)
    end

# == COLLECTION ==

    def [](name)
      Arango::Collection.new(name: name, database: self)
    end

    def collection(name:, body: {}, type: :document)
      Arango::Collection.new(name: name, database: self, body: body, type: type)
    end

    def collections(exclude_system: true)
      query = { excludeSystem: exclude_system }
      result = request("GET", "_api/collection", query: query)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Collection.new(database: self, name: x[:name], body: x )
      end
    end

# == GRAPH ==

    def graphs
      result = request("GET", "_api/gharial")
      return result if return_directly?(result)
      result[:graphs].map do |graph|
        Arango::Graph.new(database: self, name: graph[:_key], body: graph)
      end
    end

    def graph(name:, edge_definitions: [], orphan_collections: [],
      body: {})
      Arango::Graph.new(name: name, database: self, edge_definitions: edge_definitions, orphan_collections: orphan_collections, body: body)
    end

# == QUERY ==

    def query_properties
      request("GET", "_api/query/properties")
    end

    def change_query_properties(enabled: nil, max_query_string_length: nil, max_slow_queries: nil, slow_query_threshold: nil, track_bind_vars: nil,
                                track_slow_queries: nil)
      body = {
        enabled:              enabled,
        maxQueryStringLength: max_query_string_length,
        maxSlowQueries:       max_slow_queries,
        slowQueryThreshold:   slow_query_threshold,
        trackBindVars:        track_bind_vars,
        trackSlowQueries:     track_slow_queries
      }
      request("PUT", "_api/query/properties", body: body)
    end

    def current_query
      request("GET", "_api/query/current")
    end

    def slow_queries
      request("GET", "_api/query/slow")
    end

    def stop_slow_queries
      result = request("DELETE", "_api/query/slow")
      return return_delete(result)
    end

# === QUERY CACHE ===

    def clear_query_cache
      result = request("DELETE", "_api/query-cache")
      return return_delete(result)
    end

    def retrieve_query_cache
      request("GET", "_api/query-cache/entries")
    end

    def property_query_cache
      request("GET", "_api/query-cache/properties")
    end

    def change_property_query_cache(mode:, max_results: nil)
      satisfy_category?(mode, %w[off on demand])
      body = { mode: mode, maxResults: max_results }
      database.request("PUT", "_api/query-cache/properties", body: body)
    end

# === AQL ===

  def aql(query:, batch_size: nil, bind_vars: nil, cache: nil, count: nil, fail_on_warning: nil, full_count: nil, intermediate_commit_count: nil,
          intermediate_commit_size: nil, max_plans: nil, max_transaction_size: nil, max_warning_count: nil, memory_limit: nil, optimizer_rules: nil,
          profile: nil, satellite_sync_wait: nil, skip_inaccessible_collections: nil, ttl: nil)
    Arango::AQL.new(query: query, database: self, batch_size: batch_size, bind_vars: bind_vars, cache: cache, count: count,
                    fail_on_warning: fail_on_warning, full_count: full_count, intermediate_commit_count: intermediate_commit_count,
                    intermediate_commit_size: intermediate_commit_size, max_plans: max_plans, max_transaction_size: max_transaction_size,
                    max_warning_count: max_warning_count, memory_limit: memory_limit, optimizer_rules: optimizer_rules, profile: profile,
                    satellite_sync_wait: satellite_sync_wait, skip_inaccessible_collections: skip_inaccessible_collections, ttl: ttl)
  end

# === AQL FUNCTION ===

    def aql_functions(namespace: nil)
      request("GET", "_api/aqlfunction", query: { namespace: namespace }, key: :result)
    end

    def create_aql_function(code:, name:, is_deterministic: nil)
      body = { code: code, name: name, isDeterministic: is_deterministic }
      request("POST", "_api/aqlfunction", body: body)
    end

    def delete_aql_function(name:)
      result = request("DELETE", "_api/aqlfunction/#{name}")
      return return_delete(result)
    end

    # === REPLICATION ===

    def inventory(batch_id:, global: nil, include_system: nil)
      query = {
        batchId: batch_id,
        global: global,
        includeSystem: include_system
      }
      request("GET", "_api/replication/inventory", query: query)
    end

    def cluster_inventory(include_system: nil)
      query = { includeSystem: include_system }
      request("GET", "_api/replication/clusterInventory", query: query)
    end

    def logger
      request("GET", "_api/replication/logger-state")
    end

    def logger_follow(from: nil, to: nil, chunk_size: nil, include_system: nil)
      query = {
        from: from,
        to:   to,
        chunkSize:     chunk_size,
        includeSystem: include_system
      }
      request("GET", "_api/replication/logger-follow", query: query)
    end

    def logger_first_tick
      request("GET", "_api/replication/logger-first-tick", key: :firstTick)
    end

    def logger_range_tick
      request("GET", "_api/replication/logger-tick-ranges")
    end

    def server_id
      request("GET", "_api/replication/server-id", key: :serverId)
    end

    def range
      request("GET", "_api/wal/range")
    end

    def last_tick
      request("GET", "_api/wal/lastTick")
    end

    def tail(from: nil, to: nil, global: nil, chunk_size: nil,
      server_id: nil, barrier_id: nil)
      query = {
        from: from,
        to: to,
        barrierID: barrier_id,
        chunkSize: chunk_size,
        global: global,
        serverID: server_id,
      }
      request("GET", "_api/wal/tail", query: query)
    end

    def replication(master:, adaptive_polling: nil, auto_resync: nil, auto_resync_retries: nil, chunk_size: nil, connect_timeout: nil,
                    connection_retry_wait_time: nil, idle_max_wait_time: nil, idle_min_wait_time: nil, include_system: true, incremental: nil,
                    initial_sync_max_wait_time: nil, max_connect_retries: nil, request_timeout: nil, require_from_present: nil,
                    restrict_collections: nil, restrict_type: nil, verbose: nil)
      Arango::Replication.new(slave: self, master: master, adaptive_polling: adaptive_polling, auto_resync: auto_resync,
                              auto_resync_retries: auto_resync_retries, chunk_size: chunk_size, connect_timeout: connect_timeout,
                              connection_retry_wait_time: connection_retry_wait_time, idle_max_wait_time: idle_max_wait_time,
                              idle_min_wait_time: idle_min_wait_time, include_system: include_system, incremental: incremental,
                              initial_sync_max_wait_time: initial_sync_max_wait_time, max_connect_retries: max_connect_retries,
                              request_timeout: request_timeout, require_from_present: require_from_present,
                              restrict_collections: restrict_collections, restrict_type: restrict_type, verbose: verbose)
    end

    def replication_as_master(slave:, adaptive_polling: nil, auto_resync: nil, auto_resync_retries: nil, chunk_size: nil, connect_timeout: nil,
                              connection_retry_wait_time: nil, idle_max_wait_time: nil, idle_min_wait_time: nil, include_system: true,
                              incremental: nil, initial_sync_max_wait_time: nil, max_connect_retries: nil, request_timeout: nil,
                              require_from_present: nil, restrict_collections: nil, restrict_type: nil, verbose: nil)
      Arango::Replication.new(master: self, slave: slave, adaptive_polling: adaptive_polling, auto_resync: auto_resync,
                              auto_resync_retries: auto_resync_retries, chunk_size: chunk_size, connect_timeout: connect_timeout,
                              connection_retry_wait_time: connection_retry_wait_time, idle_max_wait_time: idle_max_wait_time,
                              idle_min_wait_time: idle_min_wait_time, include_system: include_system, incremental: incremental,
                              initial_sync_max_wait_time: initial_sync_max_wait_time, max_connect_retries: max_connect_retries,
                              request_timeout: request_timeout, require_from_present: require_from_present,
                              restrict_collections: restrict_collections, restrict_type: restrict_type, verbose: verbose)
    end

# === FOXX ===

    def foxx(body: {}, development: nil, legacy: nil, mount:, name: nil, provides: nil, setup: nil, teardown: nil, type: "application/json",
             version: nil)
      Arango::Foxx.new(body: body, database: self, development: development, legacy: legacy, mount: mount, name: name, provides: provides,
                       setup: setup, teardown: teardown, type: type, version: version)
    end

    def foxxes
      result = request("GET", "_api/foxx")
      return result if return_directly?(result)
      result.map do |fox|
        Arango::Foxx.new(database: self, mount: fox[:mount], body: fox)
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
      user.add_database_access(grant: grant, database: @name)
    end

    def revoke_user_access(user:)
      user = check_user(user)
      user.revoke_database_access(database: @name)
    end

    def user_access(user:)
      user = check_user(user)
      user.database_access(database: @name)
    end

# === VIEW ===

    def views
      result = request("GET", "_api/view", key: :result)
      return result if return_directly?(result)
      result.map do |view|
        Arango::View.new(database: self, id: view[:id], name: view[:name], type: view[:type])
      end
    end

    def view(name:)
      Arango::View.new(database: self, name: name)
    end

# === TASK ===

    def task(body: {}, command: nil, created: nil, id: nil, name: nil, params: nil, period: nil, type: nil)
      Arango::Task.new(body: body, command: command, created: created, database: self, id: id, name: name, params: params, period: period, type: type)
    end

    def tasks
      result = request("GET", "_api/tasks")
      return result if return_directly?(result)
      result.delete_if{|k| k[:database] != @name}
      result.map do |task|
        Arango::Task.new(body: task, database: self)
      end
    end

# === TRANSACTION ===

    def transaction(action:, intermediate_commit_count: nil, intermediate_commit_size: nil, lock_timeout: nil, max_transaction_size: nil, params: nil,
                    read: [], wait_for_sync: nil, write: [])
      Arango::Transaction.new(action: action, database: self, intermediate_commit_count: intermediate_commit_count,
                              intermediate_commit_size: intermediate_commit_size, lock_timeout: lock_timeout,
                              max_transaction_size: max_transaction_size, params: params, read: read, wait_for_sync: wait_for_sync, write: write)
    end
  end
end
