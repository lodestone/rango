module Arango
  module Requests
    module Index
      class Delete < Arango::Request
        request_method :delete

        uri_template '{/dbcontext}/_api/index/{id}'

        code 200, :success
        code 404, "Index unknown!"
      end
    end
  end
end
