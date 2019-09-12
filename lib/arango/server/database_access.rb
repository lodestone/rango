module Arango
  class Server
    module DatabaseAccess

      # verified
      # TODO move to server
      def create_database(name: @name, users: nil)
        body = {
          name:  name,
          users: users
        }
        result = @server.request("POST", "_api/database", body: body, key: :result)
        return return_directly?(result) ? result : self
      end

      # verified
      def list_databases

      end

      def list_user_databases
        # TODO move to server?
      end
      def databases(user: false)
        if user
          result = request("GET", "_api/database/user", key: :result)
        else
          result = request("GET", "_api/database", key: :result)
        end
        return result if return_directly?(result)
        result.map{|db| Arango::Database.new(name: db, server: self)}
      end

      # verified
      def drop_database
        @server.request("DELETE", "_api/database/#{@name}", key: :result)
      end

      # verified
      def database(name:)
        Arango::Database.new(name: name, server: self)
      end

    end
  end
end