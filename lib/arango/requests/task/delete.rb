module Arango
  module Requests
    module Task
      class Delete < Arango::Request
        request_method :delete

        uri_template '/_api/tasks/{id}'

        code 200, :success
        code 404, "Task not found"
      end
    end
  end
end
