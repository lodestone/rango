module Arango
  class Server
    module Tasks
      # == TASKS ==

      def tasks
        result = request("GET", "_api/tasks")
        return result if return_directly?(result)
        result.map do |task|
          database = Arango::Database.new(name: task[:database], host: self)
          Arango::Task.new(body: task, database: database)
        end
      end
    end
  end
end