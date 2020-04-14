module Arango
  module Requests
    module Transaction
      class ListRunning < Arango::Request
        request_method :get

        uri_template '{/dbcontext}/_api/transaction'

        code 200, :success
      end
    end
  end
end
