module Arango
  class Server
    module Databases
      # Retrieves all databases.
      # @return [Array<Arango::Database>]
      def all_databases
        Arango::Database.all(server: self)
      end

      # Retrieves all databases the current user can access.
      # @return [Array<Arango::Database>]
      def all_user_databases
        Arango::Database.all_user_databases(server: self)
      end

      # Retrieves a list of all databases.
      # @return [Array<String>] List of database names.
      def list_databases
        Arango::Database.list(server: self)
      end

      # Retrieves a list of all databases the current user can access.
      # @return [Array<String>] List of database names.
      def list_user_databases
        Arango::Database.list_user_databases(server: self)
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
        db = Arango::Database.get(name, server: self)
        Arango.current_database = db if Arango.current_server == self
        db
      end
      alias fetch_database get_database
      alias retrieve_database get_database

      # Check if database exists.
      # @param name [String] Name of the database.
      # @return [Boolean]
      def exist_database?(name)
        Arango::Database.exist?(name, server: self)
      end
      alias database_exist? exist_database?
    end
  end
end
