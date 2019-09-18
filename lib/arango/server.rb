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

    # Connect to a ArangoDB server.
    # @param username [String]
    # @param password [String]
    # @param host [String]
    # @param port [String]
    # @param pool [Boolean] Use connection pooling, optional, default: true.
    # @param pool_size [Integer] Connection pool size, optional, default 5.
    # @param tls [Boolean] Use TLS for the connection, optional, default: false.
    # @return [Arango::Server]
    def initialize(username: "root", password:, host: "localhost", warning: true, port: "8529", return_output: false,
                   pool: true, pool_size: 5, timeout: 5, tls: false)
      @tls = tls
      @host = host
      @port = port
      @username = username
      @password = password
      @options = { body: {}, headers: {}, query: {}, userpwd: "#{username}:#{password}" }
      @return_output = return_output
      @warning = warning
      @active_cache = active_cache
      @pool = pool
      @pool_size = pool_size
      @timeout = timeout
      set_base_uri
      @request = Arango::Request.new(base_uri: @base_uri, options: @options)
      @internal_request = ConnectionPool.new(size: @pool_size, timeout: @timeout) { @request } if @pool
    end

    def endpoint
      "tcp://#{@host}:#{@port}"
    end

    def request(*args)
      if @pool
        @internal_request.with { |request| request.request(*args) }
      else
        @request.request(*args)
      end
    end

    # Returns information about the currently running transactions.
    # @return [Arango::Result]
    def transactions
      request("GET", "_admin/wal/transactions")
    end

    # Check if transactions are running on server.
    # @return [Boolean]
    def transactions_running?
      transactions.running_transactions > 0
    end

    private

    def download(*args)
      if @pool
        @internal_request.with{|request| request.download(*args)}
      else
        @request.download(*args)
      end
    end

    def set_base_uri
      @base_uri = "http"
      @base_uri += "s" if @tls
      @base_uri += "://#{@host}:#{@port}"
    end
  end
end
