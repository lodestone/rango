module Arango
  class Server
    module Batch
      # === BATCH ===

      def batch(requests: [])
        Arango::RequestBatch.new(server: self, requests: requests)
      end

      def create_dump_batch(ttl:, dbserver: nil)
        query = { DBserver: dbserver }
        body = { ttl: ttl }
        result = request("POST", "_api/replication/batch",
                         body: body, query: query)
        return result if return_directly?(result)
        return result[:id]
      end

      def destroy_dump_batch(id:, dbserver: nil)
        query = {DBserver: dbserver}
        result = request("DELETE", "_api/replication/batch/#{id}", query: query)
        return_delete(result)
      end

      def prolong_dump_batch(id:, ttl:, dbserver: nil)
        query = { DBserver: dbserver }
        body  = { ttl: ttl }
        result = request("PUT", "_api/replication/batch/#{id}",
                         body: body, query: query)
        return result if return_directly?(result)
        return true
      end
    end
  end
end
