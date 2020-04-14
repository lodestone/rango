module Arango
  module Requests
    module Administration
      class Engine < Arango::Request
        request_method :get

        uri_template "/_api/engine"

        code 200, :success
      end
    end
  end
end
