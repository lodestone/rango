module Arango
  class Database
    module AQLQueryCache

      def clear_query_cache
        result = execute_request(delete: "_api/query-cache")
        result.response_code == 200
      end

      def get_query_cache
        result = execute_request(get: "_api/query-cache/entries")
        result.map { |entry| Arango::Result.new(entry) }
      end

      def query_cache_properties
        execute_request(get: "_api/query-cache/properties")
      end

      def set_query_cache_properties(props)
        body = props.to_h
        body.transform_keys! { |k| k.to_s.camelize(:lower).to_sym }
        result = execute_request(put: "_api/query-cache/properties", body: body)
        result.response_code == 200
      end
    end
  end
end
