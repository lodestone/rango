module Arango
  module Requests
    module Administration
      class GetMode < Arango::Request
        request_method :get

        uri_template "/_admin/server/mode"

        code 200, :success
      end
    end
  end
end
