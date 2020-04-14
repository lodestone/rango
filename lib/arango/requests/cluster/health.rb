module Arango
  module Requests
    module Cluster
      class Health < Arango::Request
        request_method :get

        uri_template "/_admin/cluster/health"

        code 201, :success
      end
    end
  end
end
