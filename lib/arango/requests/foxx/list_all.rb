module Arango
  module Requests
    module Foxx
      class ListAll < Arango::Request
        request_method :get

        uri_template '{/dbcontext}/_api/foxx'

        param :exclude_system

        code 200, :success
      end
    end
  end
end
