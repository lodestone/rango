module Arango
  class Server
    module Administration
      # Check availability of the server.
      # @return [Boolean]
      def available?
        200 == request("GET", "_admin/server/availability", key: :code)
      end

      # Returns information about all coordinator endpoints (cluster only).
      # @return [Array<String>]
      def cluster_endpoints
        if in_cluster?
          endpoints = request("GET", "_api/cluster/endpoints", key: :endpoints)
          endpoints.map { |e| e[:endpoint] }
        end
      end

      # Returns information about all server endpoints.
      # @return [Array<String>]
      def endpoints
        endpoints = request("GET", "_api/endpoint")
        endpoints.map { |e| e[:endpoint] }
      end

      # Send back what was sent in, headers, post body etc.
      # @param request_hash [Hash] The request body.
      # @return [Hash]
      def echo(request_hash)
        result = request("POST", "_admin/echo", body: request_hash)
        Oj.load(result.requestBody, symbol_keys: true)
      end

      # Return server database engine information
      # @return [Arango::Result]
      def engine
        @engine ||= request("GET", "_api/engine")
      end

      # Return true if the server uses the mmfiles engine.
      # @return [Boolean]
      def mmfiles?
        'mmfiles' == engine.name
      end

      # Return true if the server uses the rocksdb engine.
      # @return [Boolean]
      def rocksdb?
        'rocksdb' == engine.name
      end

      # Read global logs from the server.
      # Log levels for the upto and level params:
      # - fatal or 0
      # - error or 1
      # - warning or 2
      # - info or 3
      # - debug or 4
      # The parameters upto and level are mutually exclusive.
      # All params are optional.
      # @param upto [Symbol, String, Integer] Returns all log entries up to log level upto. The default value is info.
      # @param level [Symbol, String, Integer]Returns all log entries of log level level.
      # @param start Returns all log entries such that their log entry identifier (lid value) is greater or equal to start.
      # @param size [Integer] Restricts the result to at most size log entries.
      # @param offset [Integer] Starts to return log entries skipping the first offset log entries. offset and size can be used for pagination.
      # @param search [String] Only return the log entries containing the text specified in search.
      # @param sort [Symbol, String] Sort the log entries either ascending (if sort is :asc) or descending (if sort is :desc) according to their lid values.
      # @return [Arango::Result]
      def log(upto: nil, level: nil, start: nil, size: nil, offset: nil, search: nil, sort: nil)
        sort = sort.to_s if sort
        satisfy_category?(sort, [nil, "asc", "desc"])
        query = { start: start, size: size, offset: offset, search: search, sort: sort }
        if upto
          upto = upto.to_s
          satisfy_category?(upto, [nil, "fatal", 0, "error", 1, "warning", 2, "info", 3, "debug", 4])
          query[:upto] = upto
        elsif level
          level = level.to_s
          satisfy_category?(level, [nil, "fatal", 0, "error", 1, "warning", 2, "info", 3, "debug", 4])
          query[:level] = level
        end
        request("GET", "_admin/log", query: query)
      end

      # Returns the current log level settings
      # @return [Arango::Result]
      def log_level
        request("GET", "_admin/log/level")
      end

      # Modifies the current log level settings
      # @param log_level_object [Arango::Result, Hash] Must contain all keys as obtained by log_level. Best is to get the object by calling log_level,
      #                                                modifying it, and passing it here.
      # @return Arango::Result
      def log_level=(log_level_object)
        body = if log_level_object.class == Arango::Result
                 log_level_object.to_h
               else
                 log_level_object
               end
        request("PUT", "_admin/log/level", body: body)
      end

      # Return mode information about a server.
      # @return [Symbol] one of :default or :readonly
      def mode
        request("GET", "_admin/server/mode", key: :mode).to_sym
      end

      # Set server mode.
      # @param mode [String, Symbol] one of :default or :readonly
      # @return [Symbol] one of :default or :readonly
      def mode=(mode)
        satisfy_category?(mode, ["default", "readonly", :default, :readonly])
        body = { mode: mode.to_s }
        request("PUT", "_admin/server/mode", body: body, key: :mode)
      end

      # Check if server is read only.
      # @return [Boolean]
      def read_only?
        :readonly == mode
      end

      # Reloads the routing information from the collection routing.
      # @return true
      def reload_routing
        request("GET", "_admin/routing/reload")
        true
      end

      # Returns the role of a server in a cluster.
      # SINGLE: the server is a standalone server without clustering
      # COORDINATOR: the server is a Coordinator in a cluster
      # PRIMARY: the server is a DBServer in a cluster
      # SECONDARY: this role is not used anymore
      # AGENT: the server is an Agency node in a cluster
      # UNDEFINED: in a cluster, UNDEFINED is returned if the server role cannot be
      # determined.
      # @return [String]
      def role
        @role ||= request("GET", "_admin/server/role", key: :role)
      end

      # Check if server role is AGENT.
      # @return [Boolean]
      def agent?
        role == 'AGENT'
      end

      # Check if server role is COORDINATOR.
      # @return [Boolean]
      def coordinator?
        role == 'COORDINATOR'
      end

      # Check if server role is PRIMARY.
      # @return [Boolean]
      def primary?
        role == 'PRIMARY'
      end

      # Check if server role is SECONDARY.
      # @return [Boolean]
      def secondary?
        role == 'SECONDARY'
      end

      # Check if server role is SINGLE.
      # @return [Boolean]
      def single?
        role == 'SINGLE'
      end

      # Check if server is part of a cluster.
      # @return [Boolean]
      def in_cluster?
        coordinator? || primary? || agent? || secondary?
      end

      # Returns the id of a server in a cluster.
      # @return [Boolean]
      def server_id
        request("GET", "_admin/server/id", key: :serverId) if in_cluster?
      end

      # Returns the statistics information.
      # @return [Arango::Result]
      def statistics
        request("GET", "_admin/statistics")
      end

      # Returns a description of the statistics returned by /_admin/statistics.
      # @return [Arango::Result]
      def statistics_description
        request("GET", "_admin/statistics-description")
      end

      # Returns status information about the server.
      # @return [Arango::Result]
      def status
        request("GET", "_admin/status")
      end

      # Check if the server has the enterprise license.
      # @return [Boolean]
      def enterprise?
        @enterprise ||= (status.license == 'enterprise')
      end

      # The servers current system time as a Unix timestamp with microsecond precision of the server
      # @return [Float]
      def time
        request("GET", "_admin/time", key: :time)
      end

      # Return server version details.
      # The response will contain a details attribute with additional information about included components
      # and their versions. The attribute names and internals of the details object may vary depending on platform and ArangoDB version.
      # @return [Arango::Result]
      def detailed_version
        request("GET", "_api/version", query: { details: true })
      end

      # The server version string. The string has the format “major.minor.sub”. major and minor will be numeric, and sub may contain a number or
      # a textual version.
      # @return [String]
      def version
        request("GET", "_api/version", key: :version)
      end

      # Returns the database version that this server requires.
      # @return [String]
      def target_version
        request("GET", "_admin/database/target-version", key: :version)
      end
    end
  end
end
