module Arango
  module Requests
    module Document
      class Create < Arango::Request
        request_method :post

        uri_template '{/dbcontext}/_api/document/{collection}#multiple'

        param :overwrite
        param :return_old
        param :return_new
        param :silent
        param :wait_for_sync

        # TODO
        # body_is_array

        code 201, :success
        code 202, :success
        code 400, "Body does not contain a valid JSON representation of an array of documents!"
        code 404, "Collection not found!"
      end
    end
  end
end
