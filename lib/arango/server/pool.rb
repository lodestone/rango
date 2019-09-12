module Arango
  class Server
    module Pool
      def pool=(pool)
        satisfy_category?(pool, [true, false])
        return if @pool == pool
        @pool = pool
        if @pool
          @internal_request = ConnectionPool.new(size: @size, timeout: @timeout){ @request }
        else
          @internal_request&.shutdown { |conn| conn.quit }
          @internal_request = nil
        end
      end
      alias change_pool_status pool=

      def restart_pool
        change_pool_status(false)
        change_pool_status(true)
      end
    end
  end
end