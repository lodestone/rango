module Arango
  class << self
    def driver
      @driver_class
    end

    def driver=(dc)
      @driver_class = dc
    end

    def current_server
      @current_server
    end

    def current_server=(s)
      @current_server = s
    end

    def connect_to_database(username: "root", password:, host: "localhost", port: "8529", tls: false, database:, driver_options: nil)
      server = connect_to_server(username: username, password: password, host: host, port: port, tls: false, driver_options: driver_options)
      database = server.get_database(database)
      server.current_database = database
    end

    def connect_to_server(username: "root", password:, host: "localhost", port: "8529", tls: false, driver_options: nil)
      server = Arango::Server.new(username: username, password: password, host: host, port: port, tls: tls, driver_options: driver_options)
      @current_server = server unless @current_server
      server
    end
  end

  def self.request_class_method(target_class, method_name, &block)
    promise_method_name = "batch_#{method_name}".to_sym
    target_class.define_singleton_method(method_name) do |*args|
      request_hash = instance_exec(*args, &block)
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:edge_collection)
               args.last[:edge_collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      db.execute_request(request_hash)
    end
    target_class.define_singleton_method(promise_method_name) do |*args|
      request_hash = instance_exec(*args, &block)
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:edge_collection)
             args.last[:edge_collection].database
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
           elsif args.last.key?(:edge_collection)
             args.last[:edge_collection].database
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
           elsif args.last.key?(:edge_collection)
             args.last[:edge_collection].database
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
           elsif args.last.key?(:edge_collection)
             args.last[:edge_collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      request_hash.delete(:database)
      db.execute_aql(request_hash)
    end
    target_class.define_singleton_method(promise_method_name) do |*args|
      request_hash = instance_exec(*args, &block)
      db = if args.last.key?(:collection)
             args.last[:collection].database
           elsif args.last.key?(:edge_collection)
             args.last[:edge_collection].database
           elsif args.last.key?(:database)
             args.last[:database]
           end
      db.batch_execute_aql(request_hash)
    end
  end
end
