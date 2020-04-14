module Arango
  module Requests
    module Analyzer
      class List < Arango::Request
        request_method :get

        uri_template "/_api/analyzer"

        code 200, :success
      end
    end
  end
end
