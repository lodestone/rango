module Arango
  class Database
    module Basics

      def self.included(base)
        base.instance_exec do
          def drop(name, server:)
            server.request("DELETE", "_api/database/#{name}")
          end
        end
      end
      # === GET ===
      # TODO
      def assign_attributes(result)
        return unless result.is_a?(Hash)
        @id        = result[:id]
        @is_system = result[:isSystem]
        @name      = result[:name]
        @path      = result[:path]
        if @server.active_cache && @cache_name.nil?
          @cache_name = result[:name]
          @server.cache.save(:database, @cache_name, self)
        end
      end

      def retrieve
        result = request("GET", "_api/database/current", key: :result)
        assign_attributes(result)
        return return_directly?(result) ? result : self
      end
      alias current retrieve


      def create
        body = {
          name:  @name,
          # TODO users: users
        }
        @server.request("POST", "_api/database", body: body)
        self
      end

      def exist?
        # TODO
      end

      def get
        # TODO
      end

      # == DELETE ==
      # TODO move to server

      def drop
        self.drop(@name, server: @server)
      end
      alias delete drop
      alias destroy drop

      def truncate

      end
    end
  end
end