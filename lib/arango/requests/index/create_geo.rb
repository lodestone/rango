module Arango
  module Requests
    module Index
      class CreateGeo < Arango::Request
        request_method :post

        uri_template '{/dbcontext}/_api/index#geo'

        param :collection, :required

        body :fields
        body :geo_json
        body :type

        code 200, :success
        code 201, :success
        code 404, "Collection unknown!"
      end
    end
  end
end
