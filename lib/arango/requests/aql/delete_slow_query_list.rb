module Arango
  module Requests
    module Aql
      class DeleteSlowQueryList < Arango::Request
        request_method :delete

        uri_template "/_api/query/slow"

        code 200, :success
        code 400, "Malformed request!"
      end
    end
  end
end
