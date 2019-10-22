# === DATABASE ===

module Arango
  class Database
    include Arango::Helper::Satisfaction


    include Arango::Database::AQLFunctions
    include Arango::Database::Collections
    include Arango::Database::FoxxServices
    include Arango::Database::GraphAccess
    include Arango::Database::HTTPRoute
    include Arango::Database::AQLQueries
    include Arango::Database::AQLQueryCache
    include Arango::Database::Replication
    include Arango::Database::StreamTransactions
    include Arango::Database::Tasks
    include Arango::Database::Transactions
    include Arango::Database::ViewAccess

    class << self
      # Retrieves all databases.
      # @param server [Arango::Server]
      # @return [Array<Arango::Database>]
      def all(server:)
        result = server.request(get: '_api/database').result
        result.map{ |db| Arango::Database.new(db, server: server).reload }
      end

      # Retrieves all databases the current user can access.
      # @param server [Arango::Server]
      # @return [Array<Arango::Database>]
      def all_user_databases(server:)
        result = server.request(get: '_api/database/user').result
        result.map{ |db| Arango::Database.new(db, server: server).reload }
      end

      # Get database from server.
      # @param name [String] The name of the database
      # @param server [Arango::Server]
      # @return [Arango::Database] The instance of the database.
      def get(name, server:)
        Arango::Database.new(name, server: server).reload
      end
      alias fetch get
      alias retrieve get

      # Retrieves a list of all databases.
      # @param server [Arango::Server]
      # @return [Array<String>] List of database names.
      def list(server:)
        server.request(get: '_api/database').result
      end

      # Retrieves a list of all databases the current user can access.
      # @param server [Arango::Server]
      # @return [Array<String>] List of database names.
      def list_user_databases(server:)
        server.request(get: '_api/database/user').result
      end

      # Removes a database.
      # @param name [String] The name of the database
      # @param server [Arango::Server]
      # @return nil
      def drop(name, server:)
        server.request(delete: "_api/database/#{name}")
        nil
      end
      alias delete drop
      alias destroy drop

      # Check if database exists.
      # @param name [String] Name of the database.
      # @param server [Arango::Server]
      # @return [Boolean]
      def exist?(name, server:)
        list(server: server).include?(name)
      end
    end

    # Instantiate a new database. All params except name and server are optional.
    # @param name [String]
    # @param server [Arango::Server]
    # @param id
    # @param is_system
    # @param path
    # @return [Arango::Database]
    def initialize(name, id: nil, is_system: false, path: '', server: Arango.current_server)
      send(:arango_server=, server)
      @name = name
      @is_system = is_system
      @path = path
      @id = id
    end

    # Whether or not the current database is the _system database
    # @return [Boolean]
    attr_reader :is_system

    # The name of the database
    # @return [String]
    attr_reader :name

    # The filesystem path of the current database
    # @return [String]
    attr_reader :path

    attr_accessor :arango_server

    # Creates the database on the server.
    # @return [Arango::Database] self
    def create
      # TODO users: users
      body = { name: @name }
      @arango_server.request(post: '_api/database', body: body)
      self
    end

    # Reload database properties.
    # @return [Arango::Database] self
    def reload
      result = request(get: '_api/database/current')
      _update_attributes(result.result)
      self
    end
    alias refresh reload
    alias retrieve reload

    # Remove database from the server.
    # @return nil
    def drop
      self.class.drop(@name, server: @arango_server)
      nil
    end
    alias delete drop
    alias destroy drop

    # Returns the database version that this server requires.
    # @return [String]
    def target_version
      request(get: '_admin/database/target-version').version
    end

    def request(get: nil, head: nil, patch: nil, post: nil, put: nil, delete: nil, body: nil, headers: nil, query: nil, block: nil)
      @arango_server.request(get: get, head: head, patch: patch, post: post, put: put, delete: delete,
                             db: @name, body: body, headers: headers, query: query, block: block)
    end

    def execute_request(get: nil, head: nil, patch: nil, post: nil, put: nil, delete: nil, body: nil, headers: nil, query: nil, block: nil)
      @arango_server.request(get: get, head: head, patch: patch, post: post, put: put, delete: delete,
                             db: @name, body: body, headers: headers, query: query, block: block)
    end

    def execute_requests(requests)
      batch = Arango::RequestBatch.new(database: self)
      requests.each { |request_h| batch.add_request(**request_h) }
      batch.execute
    end

    def batch_request(request_hash)
      promise = Promise.new
      request_hash[:promise] = promise
      batch = _promise_batch
      batch.add_request(**request_hash)
      promise
    end

    def execute_batched_requests
      batch = @_promise_batch
      @_promise_batch = nil
      batch.execute
      nil
    end

    private

    def _promise_batch
      @_promise_batch ||= Arango::RequestBatch.new(database: self)
    end

    def _update_attributes(result)
      %i[id isSystem name path].each do |key|
        instance_variable_set("@#{key.to_s.underscore}", result[key]) if result.key?(key)
      end
    end
  end
end
