module Arango
  class Server
    module Config
      attr_reader :active_cache, :async, :base_uri, :cache, :host, :password, :port, :return_output, :tls, :username
      attr_accessor :size, :timeout, :verbose, :warning

      def username=(username)
        @username = username
        @options[:basic_auth][:username] = @username
        @request.options = options
      end

      def password=(password)
        @password = password
        @options[:basic_auth][:password] = @password
        @request.options = options
      end

      def host=(host)
        @host = host
        update_base_uri
      end

      def port=(port)
        @port = port
        update_base_uri
      end

      def tls=(tls)
        satisfy_category?(tls, [false, true])
        @tls = tls
        update_base_uri
      end

      def active_cache=(active)
        satisfy_category?(active, [true, false])
        @active_cache = active
        if @active_cache
          @cache ||= Arango::Cache.new
        elsif !@cache.nil?
          @cache.clear
        end
      end

      def return_output=(return_output)
        satisfy_category?(return_output, [true, false])
        @return_output = return_output
        @request.return_output = return_output
      end

      def verbose=(verbose)
        satisfy_category?(verbose, [true, false])
        @verbose = verbose
        @request.verbose = verbose
      end

      def async=(async)
        satisfy_category?(async, ["true", "false", false, true, "store", :store])
        case async
        when true, "true"
          @options[:headers]["x-arango-async"] = "true"
          @async = true
        when :store, "store"
          @options[:headers]["x-arango-async"] = "store"
          @async = :store
        when false, "false"
          @options[:headers].delete("x-arango-async")
          @async = false
        end
        @request.async = @async
        @request.options = @options
      end
      alias assign_async async=
    end
  end
end
