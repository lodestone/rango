module Arango
  module Helper
    module Return
      def return_directly?(result)
        return result if @server.async || @server.return_output
        result == true
      end

      def return_element(result)
        return result unless @server.async
        assign_attributes(result)
        return_directly?(result) ? result : self
      end

      def return_delete(result)
        return result unless @server.async
        return_directly?(result) ? result : true
      end
    end
  end
end
