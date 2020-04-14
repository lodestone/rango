module Arango
  module Requests
    module Index
      class CreateGeneral < Arango::Request
        request_method :post

        uri_template '{/dbcontext}/_api/index#general'

        param :collection, :required

        body :deduplicate
        body :fields
        body :name
        body :sparse
        body :type
        body :unique

        code 200, :success
        code 201, :success
        code 400, "Invalid index description or unsupported index attributes!"
        code 404, "Collection unknown!"
      end
    end
  end
end
