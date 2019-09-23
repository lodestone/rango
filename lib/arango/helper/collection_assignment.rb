module Arango
  module Helper
    module CollectionAssignment
      def assign_collection(collection)
        satisfy_class?(collection, [Arango::Collection])
        @collection = collection
        @graph = @collection.graph
        @database = @collection.database
        @arango_server = @database.arango_server
      end
    end
  end
end
