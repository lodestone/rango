module Arango
  class Database
    module AQLFunctions

      def list_aql_functions(namespace: nil)
        query = nil
        query = { namespace: namespace } unless namespace.nil?
        result = execute_request(get: "_api/aqlfunction", query: query)
        result.result.map { |r| Arango::Result.new(r) }
      end

      def create_aql_function(name, code:, is_deterministic: nil)
        body = { code: code, name: name, isDeterministic: is_deterministic }
        result = execute_request(post: "_api/aqlfunction", body: body)
        result.response_code == 200 || result.response_code == 201
      end

      def drop_aql_function(name, group: nil)
        query = nil
        query = { group: group } unless group.nil?
        result = request(delete: "_api/aqlfunction/#{name}", query: query)
        result.response_code == 200
      end
    end
  end
end
