module Arango
  module Requests
    module Database
      class ListAll < Arango::Request
        request_method :get

        uri_template '{/dbcontext}/_api/database'

        code 201, :success
        code 400, "Request is invalid!"
        code 403, "Not executed within the _system database!"
      end
    end
  end
end
