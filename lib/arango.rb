module Arango
  def self.current_database
    @current_database
  end

  def self.current_database=(d)
    @current_database = d
  end

  def self.current_server
    @current_server
  end

  def self.current_server=(s)
    @current_server = s
  end

  def self.connect_to(username: "root", password:, host: "localhost", warning: true, port: "8529", return_output: false,
      pool: true, pool_size: 5, timeout: 5, tls: false, database: nil)
    @current_server = Arango::Server.new(username: username, password: password, host: host, warning: warning, port: port,
                                         return_output: return_output, pool: pool, pool_size: pool_size, timeout: timeout, tls: tls)
    @current_database = @current_server.get_database(database) if database
    @current_server
  end

  def self.request_class_method(target_class, method_name, &block)
    promise_method_name = "batch_#{method_name}".to_sym
    target_class.define_singleton_method(method_name) do |*args|
      request_hash = instance_exec(*args, &block)
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      db.execute_request(request_hash)
    end
    target_class.define_singleton_method(promise_method_name) do |*args|
      request_hash = instance_exec(*args, &block)
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      db.batch_request(request_hash)
    end
  end

  def self.multi_request_class_method(target_class, method_name, &block)
    promise_method_name = "batch_#{method_name}".to_sym
    target_class.define_singleton_method(method_name) do |*args|
      requests = instance_exec(*args, &block)
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      db.execute_requests(requests)
    end
    target_class.define_singleton_method(promise_method_name) do |*args|
      requests = instance_exec(*args, &block)
      promises = []
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      requests.each do |request_hash|
        promises << db.batch_request(request_hash)
      end
      Promise.when(*promises).then { |values| values.last }
    end
  end

  def self.aql_request_class_method(target_class, method_name, &block)
    promise_method_name = "batch_#{method_name}".to_sym
    target_class.define_singleton_method(method_name) do |*args|
      request_hash = instance_exec(*args, &block)
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      request_hash.delete(:database)
      db.execute_aql_request(request_hash)
    end
    target_class.define_singleton_method(promise_method_name) do |*args|
      request_hash = instance_exec(*args, &block)
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      db.batch_aql_request(request_hash)
    end
  end
end
