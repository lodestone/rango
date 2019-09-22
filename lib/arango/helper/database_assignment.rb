module Arango
  module Helper
    module DatabaseAssignment

      protected

      def assign_database(database)
        satisfy_class?(database, [Arango::Database])
        @database = database
        @server = @database.arango_server
      end
    end
  end
end
