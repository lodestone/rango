module Arango
  module Requests
    module Document
      class DeleteMultiple < Arango::Request
        request_method :delete

        uri_template '{/dbcontext}/_api/document/{collection}'

        param :ignore_revs
        param :return_old
        param :wait_for_sync

        # TODO
        # body_is_array

        code 200, :success
        code 202, :success
        code 404, "Collection not found!"
      end
    end
  end
end
