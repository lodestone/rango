module Arango
  module Requests
    module Index
      class Get < Arango::Request
        request_method :get

        uri_template '{/dbcontext}/_api/index/{id}'

        code 200, :success
        code 404, "Index unknown!"
      end
    end
  end
end
