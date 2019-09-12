module Arango
  module View
    module Basics
      def exist?

      end
      alias exists? exist?

      def info


      end

      def rename(name:)
        body = {name: name}
        result = @database.request("PUT", "_api/view/#{@name}/rename", body: body)
        return_element(result)
      end#

      def drop
        @database.request("DELETE", "_api/view/#{@name}", key: :result)
      end
    end
  end
end