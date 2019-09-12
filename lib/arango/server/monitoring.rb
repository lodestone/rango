module Arango
  class Server
    module Monitoring
      # === MONITORING ===

      def server_data
        request("GET", "_admin/server/id")
      end

      def cluster_health
        request("GET", "_admin/health")
      end

      def cluster_statistics dbserver:
        query = {DBserver: dbserver}
        request("GET", "_admin/clusterStatistics", query: query)
      end

    end
  end
end