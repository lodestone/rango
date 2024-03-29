module Arango
  module Requests
    module Document
      class Create < Arango::Request
        request_method :post

        uri_template '{/dbcontext}/_api/document/{collection}'

        param :overwrite
        param :return_old
        param :return_new
        param :silent
        param :wait_for_sync

        body_any

        code 201, :success
        code 202, :success
        code 400, "Body does not contain a valid JSON representation of an array of documents!"
        code 404, "Collection not found!"
        code 409, "The document with the same qualifiers in an indexed attribute conflicts with an already existing document and thus violates that unique constraint"
      end
    end
  end
end
