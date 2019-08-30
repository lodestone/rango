
module Arango
  class Server
    module Return
      def server=(server)
        satisfy_class?(server, [Arango::Server])
        @server = server
      end
      alias assign_server server=
    end
  end
end

module Arango
  class Database
    module Return
      def database=(database)
        satisfy_class?(database, [Arango::Database])
        @database = database
        @server = @database.server
      end
      alias assign_database database=
    end
  end
end

module Arango
  class Collection
    module Return
      def collection=(collection)
        satisfy_class?(collection, [Arango::Collection])
        @collection = collection
        @graph = @collection.graph
        @database = @collection.database
        @server = @database.server
      end
      alias assign_collection collection=
    end
  end
end
