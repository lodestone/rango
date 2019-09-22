module Arango
  module Helper
    module RequestMethod
      def request_method(method_name, &block)
        promise_method_name = "batch_#{method_name}".to_sym
        define_method(method_name) do |*args|
          request_hash = instance_exec(*args, &block)
          @database.execute_request(request_hash)
        end
        define_method(promise_method_name) do |*args|
          request_hash = instance_exec(*args, &block)
          @database.promise_request(request_hash)
        end
      end

      def multi_request_method(method_name, &block)
        promise_method_name = "batch_#{method_name}".to_sym
        define_method(method_name) do |*args|
          requests = instance_exec(*args, &block)
          @database.execute_requests(requests)
        end
        define_method(promise_method_name) do |*args|
          requests= instance_exec(*args, &block)
          promises = []
          requests.each do |request_hash|
            promises << @database.promise_request(request_hash)
          end
          Promise.when(*promises).then { |values| values.last }
        end
      end
    end
  end
end
