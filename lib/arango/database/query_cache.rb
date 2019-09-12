module Arango
  class Database
    module QueryCache
      # === QUERY CACHE ===

      def clear_query_cache
        result = request("DELETE", "_api/query-cache")
        return return_delete(result)
      end

      def retrieve_query_cache
        request("GET", "_api/query-cache/entries")
      end

      def property_query_cache
        request("GET", "_api/query-cache/properties")
      end

      def change_property_query_cache(mode:, max_results: nil)
        satisfy_category?(mode, %w[off on demand])
        body = { mode: mode, maxResults: max_results }
        database.request("PUT", "_api/query-cache/properties", body: body)
      end

    end
  end
end