module Arango
  module Requests
    module Collection
      class ListAll < Arango::Request
        request_method :get

        uri_template "/_api/collection"

        param :exclude_system

        code 200, :success
      end
    end
  end
end
