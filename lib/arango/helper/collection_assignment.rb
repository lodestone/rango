module Arango
  module Helper
    module CollectionAssignment
      def assign_collection(collection)
        satisfy_class?(collection, [Arango::DocumentCollection])
        @collection = collection
        @graph = @collection.graph
        @database = @collection.database
        @server = @database.server
      end
    end
  end
end