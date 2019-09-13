# === DATABASE ===

module Arango
  class Database
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::ServerAssignment

    include Arango::Database::AQLFunctions
    include Arango::Database::Basics
    include Arango::Database::CollectionAccess
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

    # TODO see js api https://www.arangodb.com/docs/devel/drivers/js-reference-database.html
    def initialize(name, server:)
      assign_server(server)
      @name = name
      @server = server
      @is_system = nil
      @path = nil
      @id = nil
    end

    def aquire_host_list
      # TODO
    end

    def use_database
      # TODO
    end

    def use_basic_auth
      # TODO
    end

    def use_bearer_auth
      # TODO
    end

    def login
      # TODO
    end

    def target_version

    end

    def version
      # TODO
    end

    def close
      # TODO
    end

    # === DEFINE ===
    attr_reader :cache_name, :id, :is_system, :path, :server
    attr_accessor :name

    # === TO HASH ===
    # why?
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
      @server.request(action, url, body: body, headers: headers, query: query, key: key, skip_to_json: skip_to_json,
                      keep_null: keep_null)
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
  end
end
