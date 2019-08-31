module Arango
  module Helper
    module ServerAssignment
      def assign_server(server)
        satisfy_class?(server, [Arango::Server])
        @server = server
      end
    end
  end
end