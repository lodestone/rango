module Arango
  module Requests
    module Collection
      class Delete < Arango::Request
        request_method :delete

        uri_template "/_api/collection/{name}"

        param :is_system

        code 200, :success
        code 400, "Collection name is missing!"
        code 404, "collection or view not found"
      end
    end
  end
end
