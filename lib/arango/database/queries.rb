module Arango
  class Database
    module Queries
      # == QUERY ==

      def aql(query:, batch_size: nil, bind_vars: nil, cache: nil, count: nil, fail_on_warning: nil, full_count: nil, intermediate_commit_count: nil,
              intermediate_commit_size: nil, max_plans: nil, max_transaction_size: nil, max_warning_count: nil, memory_limit: nil, optimizer_rules: nil,
              profile: nil, satellite_sync_wait: nil, skip_inaccessible_collections: nil, ttl: nil)
        Arango::AQL.new(query: query, database: self, batch_size: batch_size, bind_vars: bind_vars, cache: cache, count: count,
                        fail_on_warning: fail_on_warning, full_count: full_count, intermediate_commit_count: intermediate_commit_count,
                        intermediate_commit_size: intermediate_commit_size, max_plans: max_plans, max_transaction_size: max_transaction_size,
                        max_warning_count: max_warning_count, memory_limit: memory_limit, optimizer_rules: optimizer_rules, profile: profile,
                        satellite_sync_wait: satellite_sync_wait, skip_inaccessible_collections: skip_inaccessible_collections, ttl: ttl)
      end

      def explain(aql, bind_vars: nil, options: nil)
        # TODO Explains a database query using the given query and bindVars and returns one or more plans.
      end

      def query(aql, bind_vars: nil, options: nil)
        # TODO Performs a database query using the given query and bindVars
      end

      def parse(aql)
        # Parses the given query and returns the result.
      end

      def query_tracking
        # TODO Fetches the query tracking properties.
      end
      # def query_properties
      #   request("GET", "_api/query/properties")
      # end

      def set_query_tracking(props)
        # Modifies the query tracking properties.
      end
      # def change_query_properties(enabled: nil, max_query_string_length: nil, max_slow_queries: nil, slow_query_threshold: nil, track_bind_vars: nil,
      #                             track_slow_queries: nil)
      #   body = {
      #     enabled:              enabled,
      #     maxQueryStringLength: max_query_string_length,
      #     maxSlowQueries:       max_slow_queries,
      #     slowQueryThreshold:   slow_query_threshold,
      #     trackBindVars:        track_bind_vars,
      #     trackSlowQueries:     track_slow_queries
      #   }
      #   request("PUT", "_api/query/properties", body: body)
      # end

      def current_query
        request("GET", "_api/query/current")
      end

      def list_running_queries
        # TODO
      end

      def list_slow_queries
        # TODO
        request("GET", "_api/query/slow")
      end

      def clear_slow_queries
        # TODO
      end
      # def stop_slow_queries
      #   result = request("DELETE", "_api/query/slow")
      #   return return_delete(result)
      # end

      def kill_query
        # TODO
      end
    end
  end
end