module Arango
  class Server
    module Tasks

      # Get all tasks.
      #
      # @return [Array] Array of Arango::Task
      def all_tasks
        Arango::Task.all(server: self)
      end

      # Create a new task with given id, task is saved to the database.
      #
      # @param id [String]
      # @param command [String] The javascript code to execute.
      # @param name [String] The task name, optional.
      # @param offset [Integer] The number of seconds initial delay, optional.
      # @param params [Hash] Hash of params to pass to the command, optional.
      # @param period [Integer] Number of seconds between executions, optional.
      # @return [Arango::Task]
      def create_task(id, command:, name: nil, offset: nil, params: nil, period: nil)
        Arango::Task.new(id, command: command, name: name, offset: offset, params: params, period: period, server: self).create
      end

      # Get a task from the server.
      #
      # @param id [String]
      # @return [Arango::Task]
      def get_task(id)
        Arango::Task.get(id, server: self)
      end

      # Instantiate a new task with given id, task is not saved to the database.
      #
      # @param id [String]
      # @param command [String] The javascript code to execute, optional.
      # @param name [String] The task name, optional.
      # @param offset [Integer] The number of seconds initial delay, optional.
      # @param params [Hash] Hash of params to pass to the command, optional.
      # @param period [Integer] Number of seconds between executions, optional.
      # @return [Arango::Task]
      def new_task(id, command: nil, name: nil, offset: nil, params: nil, period: nil)
        Arango::Task.new(id, command: command, name: name, offset: offset, params: params, period: period, server: self)
      end

      # Get a list of all task ids.
      #
      # @return [Array] Array of Strings.
      def list_tasks
        Arango::Task.list(server: self)
      end

      # Delete task with given id.
      #
      # @param id [String]
      # @return [Boolean] Returns true if task has been deleted.
      def drop_task(id)
        Arango::Task.delete(id, server: self)
      end
      alias delete_task drop_task
      alias destroy_task drop_task
    end
  end
end