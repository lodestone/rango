module Arango
  class Database
    module AQLFunctions
      # === AQL FUNCTION ===

      def list_aql_functions(namespace: nil)
        request("GET", "_api/aqlfunction", query: { namespace: namespace }, key: :result)
      end

      def create_aql_function(code:, name:, is_deterministic: nil)
        body = { code: code, name: name, isDeterministic: is_deterministic }
        request("POST", "_api/aqlfunction", body: body)
      end

      def drop_aql_function(name)
        result = request("DELETE", "_api/aqlfunction/#{name}")
        return return_delete(result)
      end
    end
  end
end