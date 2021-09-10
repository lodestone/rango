module Arango
  module Requests
    module Administration
      class Time < Arango::Request
        request_method :get

        uri_template "/_admin/time"

        code 200, :success
      end
    end
  end
end
