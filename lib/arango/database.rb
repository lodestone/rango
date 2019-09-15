# === DATABASE ===

module Arango
  class Database
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::ServerAssignment

    include Arango::Database::AQLFunctions
    include Arango::Database::Collections
    include Arango::Database::FoxxServices
    include Arango::Database::GraphAccess
    include Arango::Database::HTTPRoute
    include Arango::Database::Queries
    include Arango::Database::QueryCache
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
        result = server.request("GET", "_api/database", key: :result)
        result.map{ |db| Arango::Database.new(db, server: server).reload }
      end

      # Retrieves all databases the current user can access.
      # @param server [Arango::Server]
      # @return [Array<Arango::Database>]
      def all_user_databases(server:)
        result = server.request("GET", "_api/database/user", key: :result)
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
        server.request("GET", "_api/database", key: :result)
      end

      # Retrieves a list of all databases the current user can access.
      # @param server [Arango::Server]
      # @return [Array<String>] List of database names.
      def list_user_databases(server:)
        server.request("GET", "_api/database/user", key: :result)
      end

      # Removes a database.
      # @param name [String] The name of the database
      # @param server [Arango::Server]
      # @return nil
      def drop(name, server:)
        server.request("DELETE", "_api/database/#{name}")
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
    def initialize(name, id: nil, is_system: false, path: '', server:)
      assign_server(server)
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

    attr_reader :server

    # Creates the database on the server.
    # @return [Arango::Database] self
    def create
      # TODO users: users
      body = { name: @name }
      @server.request("POST", "_api/database", body: body)
      self
    end

    # Reload database properties.
    # @return [Arango::Database] self
    def reload
      result = request("GET", "_api/database/current", key: :result)
      _update_attributes(result)
      self
    end
    alias refresh reload
    alias retrieve reload

    # Remove database from the server.
    # @return nil
    def drop
      self.class.drop(@name, server: @server)
    end
    alias delete drop
    alias destroy drop

    # Returns the database version that this server requires.
    # @return [String]
    def target_version
      request("GET", "_admin/database/target-version", key: :version)
    end

    def request(action, url, body: {}, headers: {}, query: {}, key: nil, skip_to_json: false, keep_null: false)
      url = "_db/#{@name}/#{url}"
      @server.request(action, url, body: body, headers: headers, query: query, key: key, skip_to_json: skip_to_json, keep_null: keep_null)
    end

    private

    def _update_attributes(result)
      %i[id isSystem name path].each do |key|
        instance_variable_set("@#{key.to_s.underscore}", result[key]) if result.key?(key)
      end
    end
  end
end
