module Arango
  module Requests
    module Index
      class CreateFulltext < Arango::Request
        request_method :post

        uri_template '{/dbcontext}/_api/index#fulltext'

        param :collection, :required

        body :fields
        body :min_length
        body :type

        code 200, :success
        code 201, :success
        code 404, "Collection unknown!"
      end
    end
  end
end
