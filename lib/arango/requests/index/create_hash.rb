module Arango
  module Requests
    module Index
      class CreateHash < Arango::Request
        request_method :post

        uri_template '{/dbcontext}/_api/index#hash'

        param :collection, :required

        body :deduplicate
        body :fields
        body :sparse
        body :type
        body :unique

        code 200, :success
        code 201, :success
        code 400, "Documents violating uniqueness!"
        code 404, "Collection unknown!"
      end
    end
  end
end
