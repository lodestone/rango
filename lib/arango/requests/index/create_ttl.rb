module Arango
  module Requests
    module Index
      class CreateTtl < Arango::Request
        request_method :post

        uri_template '{/dbcontext}/_api/index#ttl'

        param :collection, :required

        body :expire_after
        body :fields
        body :type

        code 200, :success
        code 201, :success
        code 400, "Collection already contains another ttl index!"
        code 404, "Collection unknown!"
      end
    end
  end
end
