module Arango
  class Server
    module Administration
      def all_endpoints
        request("GET", "_api/endpoint")
      end

      def available?
        200 == request("GET", "_admin/server/availability", key: :code)
      end

      def cluster_endpoints
        request("GET", "_api/cluster/endpoints", key: :endpoints)
      end

      def echo(request_object)
        result = request("POST", "_admin/echo", body: request_object)
        Oj.load(result.requestBody, symbol_keys: true)
      end

      def engine
        @engine ||= request("GET", "_api/engine")
      end

      def mmfiles?
        'mmfiles' == engine.name
      end

      def rocksdb?
        'rocksdb' == engine.name
      end

      def log(upto: nil, level: nil, start: nil, size: nil, offset: nil, search: nil, sort: nil)
        satisfy_category?(upto, [nil, "fatal", 0, "error", 1, "warning", 2, "info", 3, "debug", 4])
        satisfy_category?(sort, [nil, "asc", "desc"])
        query = { start: start, size: size, offset: offset, search: search, sort: sort }
        if upto
          query[:upto] = upto
        elsif level
          query[:level] = level
        end
        result = request("GET", "_admin/log", query: query)
        result
      end

      def log_level
        request("GET", "_admin/log/level")
      end

      def log_level=(log_level_object)
        body = if log_level_object.class == Arango::Result
                 log_level_object.to_h
               else
                 log_level_object
               end
        request("PUT", "_admin/log/level", body: body)
      end

      def mode
        request("GET", "_admin/server/mode", key: :mode).to_sym
      end

      def mode=(mode)
        satisfy_category?(mode, ["default", "readonly", :default, :readonly])
        body = { mode: mode.to_s }
        request("PUT", "_admin/server/mode", body: body, key: :mode)
      end

      def read_only?
        'readonly' == request("GET", "_admin/routing/reload", key: :mode)
      end

      def reload_routing
        request("GET", "_admin/routing/reload")
        true
      end

      def role
        request("GET", "_admin/server/role", key: :role)
      end

      def server_id
        request("GET", "_api/replication/server-id", key: :serverId)
      end

      def statistics
        request("GET", "_admin/statistics")
      end

      def statistics_description
        request("GET", "_admin/statistics-description")
      end

      def status
        request("GET", "_admin/status")
      end

      def time
        request("GET", "_admin/time", key: :time)
      end

      def version(details: nil)
        query = { details: details }
        request("GET", "_api/version", query: query)
      end
    end
  end
end