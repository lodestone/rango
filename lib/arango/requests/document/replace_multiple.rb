module Arango
  module Requests
    module Document
      class ReplaceMultiple < Arango::Request
        request_method :put

        uri_template '{/dbcontext}/_api/document/{collection}'

        param :ignore_revs
        param :return_new
        param :return_old
        param :wait_for_sync

        body_array

        code 201, :success
        code 202, :success
        code 400, "Body does not contain a valid JSON representation of an array of documents!"
        code 404, "Collection not found!"
      end
    end
  end
end
