module Arango
  module Requests
    module Administration
      class Statistics < Arango::Request
        request_method :get

        uri_template "/_admin/statistics-description"

        code 200, :success
      end
    end
  end
end
