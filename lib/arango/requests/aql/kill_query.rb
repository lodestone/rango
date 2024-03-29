module Arango
  module Requests
    module AQL
      class KillQuery < Arango::Request
        request_method :delete

        uri_template "/_api/query/{id}"

        code 200, :success
        code 400, "Malformed request!"
        code 404, "Query not found!"
      end
    end
  end
end
