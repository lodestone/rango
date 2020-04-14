module Arango
  module Requests
    module View
      class ListAll < Arango::Request
        request_method :get

        uri_template '{/dbcontext}/_api/view'

        code 200, :success
      end
    end
  end
end
