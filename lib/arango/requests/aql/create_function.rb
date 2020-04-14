module Arango
  module Requests
    module Aql
      class DeleteFunction < Arango::Request
        request_method :delete

        uri_template "/_api/aqlfunction/{name}"

        param :group

        code 200, :success
        code 400, "Function name is malformed!"
        code 404, "Function does not exist!"
      end
    end
  end
end
