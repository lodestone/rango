module Arango
  module Requests
    module Aql
      class GetSlowQueryList < Arango::Request
        request_method :get

        uri_template "/_api/query/slow"

        code 200, :success
        code 400, "Malformed request!"
      end
    end
  end
end
