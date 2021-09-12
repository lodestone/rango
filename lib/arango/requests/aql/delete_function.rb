module Arango
  module Requests
    module AQL
      class DeleteFunctions < Arango::Request
        request_method :delete

        uri_template "/_api/aqlfunction"

        param :namespace

        code 200, :success
        code 400, "Function name malformed!"
      end
    end
  end
end
