module Arango
  class RequestBatch
    include Arango::Helper::Satisfaction
    include Arango::Helper::Return
    include Arango::Helper::DatabaseAssignment
    include Arango::Helper::ServerAssignment

    # Initialize a new request batch.
    # Request must be a Hash with the keys:
    # - :id, optional
    # - :method, required
    # - :uri, required
    # - :body, optional
    # @param server [Arango::Server] The server the requests should be run on. One of server or database must be given.
    # @param database [Arango::Database] The database the requests should be run on. One of server or database must be given.
    # @param requests [Array<Hash>, Hash] Array of requests or a single request as Hash, optional.
    # @return [Arango::RequestBatch]
    def initialize(server: nil, database: nil, requests: [])
      @id = 1
      if database
        assign_database(database)
      elsif server
        assign_server(server)
      else
        raise Arango::Error.new(err: :server_or_database_must_be_given)
      end
      send(:requests=, requests)
      @boundary = "ArangoDriverRequestPart"
      @headers = { 'Content-Type' => "multipart/form-data; boundary=#{@boundary}" }
    end

    attr_reader :database, :requests, :server

    # Assign a bunch of requests.
    # @param requests [Array<Hash>, Hash] Array of requests or a single request as Hash, optional.
    # @return [Array<Hash>]
    def requests=(requests)
      requests = [requests] unless requests.is_a?(Array)
      @requests = {}
      requests.each do |request|
        add_request(request[:id], request[:method], request[:uri], body: request[:body])
      end
      return @requests
    end

    # Add a single request
    # @param id [String] optional
    # @param method [String]
    # @param uri [String]
    # @param body [Hash] optional
    def add_request(id = @id, method, uri, body: nil)
      id = @id unless id
      id = id.to_s
      @requests[id] = {
        id:      id,
        method:  method,
        uri:     uri,
        body:    body
      }.delete_if{|_,v| v.nil?}
      @id += 1
      @requests[id]
    end
    alias modify_request add_request

    def delete_request(id)
      @requests.delete(id)
      @requests
    end

    # Execute the request batch.
    # @return [Array<Arango::Result]
    def execute
      body = ""
      @requests.each do |id, request|
        body << "--#{@boundary}\r\n"
        body << "Content-Type: application/x-arango-batchpart\r\n"
        body << "Content-Id: #{id}\r\n\r\n"
        body << "#{request[:method]} #{request[:uri]} HTTP/1.1\r\n"
        # TODO headers
        body << "\r\n"
        body << "#{Oj.dump(request[:body], mode: :json)}\r\n" unless request[:body].nil?
      end
      body << "--#{@boundary}--\r\n\r\n" if @requests.length > 0
      result = if @database
                 @database.request("POST", "_api/batch", body: body, headers: @headers)
               else
                 @server.request("POST", "_api/batch", body: body, headers: @headers)
               end
      result_hash = _parse_result(result)
      _check_for_errors(result_hash)
    end

    private

    def _check_for_errors(result_hash)
      result_hash.each do |k, result|
        if !result.is_array? && result.error?
          raise Arango::ErrorDB.new(message: result.error_message, code: result.code, data: result.to_h, error_num: result.error_num,
                                    action: '', url: '', request: { request_part: k })
        end
      end
      result_hash
    end

    def _parse_result(result)
      parts = result.split("--#{@boundary}")
      result_hash = {}
      parts.each do |part|
        if part == "" || part == "--"
          false
        else
          key = nil
          is_json = false
          body = nil
          code = 0
          lines = part.split("\r\n")
          lines.each do |line|
            if line.start_with?('Content-Id: ')
              key = line[12..-1]
            elsif line.start_with?('HTTP/1.1 ')
              code = line[9..12].to_i
            elsif line.start_with?('Content-Type: application/json')
              is_json = true
            elsif line.start_with?('{') || line.start_with?('[')
              if is_json
                body = Oj.load(line, mode: :json)
              else
                body = line
              end
            end
          end
          res = Arango::Result.new(is_json ? body : { body: body })
          res.response_code = code
          result_hash[key.to_sym] = res
        end
      end
      result_hash
    end
  end
end
