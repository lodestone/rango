module Arango
  module Requests
    module Administration
      class ReloadRouting < Arango::Request
        request_method :post

        uri_template "/_admin/routing/reload"

        code 200, :success
      end
    end
  end
end
