module Arango
  class Server
    module Databases
      # Retrieves all databases.
      # @return [Array] Array of Arango::Database.
      def all_databases
        result = request("GET", "_api/database", key: :result)
        result.map{|db| Arango::Database.new(db, server: self)}
      end

      # Retrieves all databases the current user can access.
      # @return [Array] Array of Arango::Database.
      def all_user_databases
        result = request("GET", "_api/database/user", key: :result)
        result.map{|db| Arango::Database.new(db, server: self)}
      end

      # Retrieves a list of all databases.
      # @return [Array] List of database names.
      def list_databases
        request("GET", "_api/database", key: :result)
      end

      # Retrieves a list of all databases the current user can access.
      # @return [Array] List of database names.
      def list_user_databases
        request("GET", "_api/database/user", key: :result)
      end

      # Creates a new database.
      # @param name [String] The name of the database
      # @return [Arango::Database] The instance of the database created.
      def create_database(name)
        Arango::Database.new(name, server: self).create
      end

      # Instantiates a new database, but does not store it on th server.
      # @param name [String] The name of the database
      # @return [Arango::Database] The instance of the database.
      def new_database(name)
        Arango::Database.new(name, server: self)
      end

      # Removes a database.
      # @param name [String] The name of the database
      # @return nil
      def drop_database(name)
        Arango::Database.drop(name, server: self)
      end
      alias delete_database drop_database
      alias destroy_database drop_database

      # Get database from server.
      # @param name [String] The name of the database
      # @return [Arango::Database] The instance of the database.
      def get_database(name)
        Arango::Database.get(name, server: self)
      end
    end
  end
end