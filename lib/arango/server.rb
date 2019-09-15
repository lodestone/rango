# === SERVER ===

module Arango
  class Server
    include Arango::Helper::Satisfaction

    include Arango::Server::Administration
    include Arango::Server::Config
    include Arango::Server::Databases
    include Arango::Server::Monitoring
    include Arango::Server::Pool
    include Arango::Server::Tasks

    def initialize(username: "root", password:, host: "localhost",
      warning: true, port: "8529", verbose: false, return_output: false,
      async: false, active_cache: false, pool: false, size: 5, timeout: 5,
      tls: false)
      @tls = tls
      @host = host
      @port = port
      @username = username
      @password = password
      @options = { body: {}, headers: {}, query: {}, userpwd: "#{@username}:#{@password}" }
      @verbose = verbose
      @return_output = return_output
      @warning = warning
      @active_cache = active_cache
      @cache = @active_cache ? Arango::Cache.new : nil
      @pool = pool
      @size = size
      @timeout = timeout
      @request = Arango::Request.new(return_output: @return_output,
        base_uri: @base_uri, options: @options)
      update_base_uri
      @internal_request = ConnectionPool.new(size: @size, timeout: @timeout){ @request } if @pool
    end

  # == CLUSTER ==

    def check_port(port: @port)
      request("GET", "_admin/clusterCheckPort", query: {port: port.to_s})
    end


  # === ENDPOINT ===

    def endpoint
      "tcp://#{@host}:#{@port}"
    end

  # === USER ===

    def user(password: "", name:, extra: {}, active: nil)
      Arango::User.new(host: self, password: password, name: name, extra: extra,
        active: active)
    end

    def users
      result = request("GET", "_api/user", key: :result)
      return result if return_directly?(result)
      result.map do |user|
        Arango::User.new(name: user[:user], active: user[:active],
          extra: user[:extra], host: self)
      end
    end



  # === BATCH ===

    def batch(boundary: "XboundaryX", queries: [])
      Arango::Batch.new(server: self, boundary: boundary, queries: queries)
    end

    def create_dump_batch(ttl:, dbserver: nil)
      query = { DBserver: dbserver }
      body = { ttl: ttl }
      result = request("POST", "_api/replication/batch",
        body: body, query: query)
      return result if return_directly?(result)
      return result[:id]
    end

    def destroy_dump_batch(id:, dbserver: nil)
      query = {DBserver: dbserver}
      result = request("DELETE", "_api/replication/batch/#{id}", query: query)
      return_delete(result)
    end

    def prolong_dump_batch(id:, ttl:, dbserver: nil)
      query = { DBserver: dbserver }
      body  = { ttl: ttl }
      result = request("PUT", "_api/replication/batch/#{id}",
        body: body, query: query)
      return result if return_directly?(result)
      return true
    end

  # === AGENCY ===

    def agency_config
      request("GET", "_api/agency/config")
    end

    def agency_write(body:, agency_mode: nil)
      satisfy_category?(agency_mode, ["waitForCommmitted", "waitForSequenced", "noWait", nil])
      headers = {"X-ArangoDB-Agency-Mode": agency_mode}
      request("POST", "_api/agency/write", headers: headers,
        body: body)
    end

    def agency_read(body:, agency_mode: nil)
      satisfy_category?(agency_mode, ["waitForCommmitted", "waitForSequenced", "noWait", nil])
      headers = {"X-ArangoDB-Agency-Mode": agency_mode}
      request("POST", "_api/agency/read", headers: headers,
        body: body)
    end

    # === MISCELLANEOUS FUNCTIONS ===


    def flush_wal(waitForSync: nil, waitForCollector: nil)
      body = {
        waitForSync: waitForSync,
        waitForCollector: waitForCollector
      }
      result = request("PUT", "_admin/wal/flush", body: body)
      return return_directly?(result) ? result: true
    end

    def property_wal
      request("GET", "_admin/wal/properties")
    end

    def change_property_wal(allowOversizeEntries: nil, logfileSize: nil,
      historicLogfiles: nil, reserveLogfiles: nil, throttleWait: nil,
      throttleWhenPending: nil)
      body = {
        allowOversizeEntries: allowOversizeEntries,
        logfileSize: allowOversizeEntries,
        historicLogfiles: historicLogfiles,
        reserveLogfiles: reserveLogfiles,
        throttleWait: throttleWait,
        throttleWhenPending: throttleWhenPending
      }
      request("PUT", "_admin/wal/properties", body: body)
    end

    def transactions
      request("GET", "_admin/wal/transactions")
    end

    def database_version
      request("GET", "_admin/database/target-version", key: :version)
    end

    def shutdown
      result = request("DELETE", "_admin/shutdown")
      return return_directly?(result) ? result: true
    end

    def test(body:)
      request("POST", "_admin/test", body: body)
    end



    def return_directly?(result)
      return @async != false || @return_direct_result
      return result if result == true
    end

    def return_delete(result)
      return result if @async != false
      return return_directly?(result) ? result : true
    end

    def request(*args)
      if @pool
        @internal_request.with{|request| request.request(*args)}
      else
        @request.request(*args)
      end
    end

    private

    def download(*args)
      if @pool
        @internal_request.with{|request| request.download(*args)}
      else
        @request.download(*args)
      end
    end

    def update_base_uri
      @base_uri = "http"
      @base_uri += "s" if @tls
      @base_uri += "://#{@host}:#{@port}"
      @request.base_uri = @base_uri
    end
  end
end
