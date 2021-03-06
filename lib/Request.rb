module Arango
  class Request
    def initialize(return_output:, base_uri:, options:, verbose:, async:)
      @return_output = return_output
      @base_uri = base_uri
      @options = options
      @verbose = verbose
      @async = async
    end

    attr_accessor :return_output, :base_uri, :options, :verbose, :async

    def request(action, url, body: {}, headers: {}, query: {},
      key: nil, return_direct_result: @return_output, skip_to_json: false,
      keepNull: false, skip_parsing: false)
      send_url = "#{@base_uri}/"
      send_url += url

      if body.is_a?(Hash)
        body.delete_if{|k,v| v.nil?} unless keepNull
      end
      query.delete_if{|k,v| v.nil?}
      headers.delete_if{|k,v| v.nil?}
      options = @options.merge({body: body, query: query})
      options[:headers].merge!(headers)

      if ["GET", "HEAD", "DELETE"].include?(action)
        options.delete(:body)
      end

      if @verbose
        puts "\n===REQUEST==="
        puts "#{action} #{send_url}\n"
        puts JSON.pretty_generate(options)
        puts "==============="
      end

      if !skip_to_json && !options[:body].nil?
        options[:body] = Oj.dump(options[:body], mode: :json)
      end
      options.delete_if{|k,v| v.empty?}

      begin
        response = case action
        when "GET"
          HTTParty.get(send_url, options)
        when "HEAD"
          HTTParty.head(send_url, options)
        when "PATCH"
          HTTParty.patch(send_url, options)
        when "POST"
          HTTParty.post(send_url, options)
        when "PUT"
          HTTParty.put(send_url, options)
        when "DELETE"
          HTTParty.delete(send_url, options)
        end
      rescue Exception => e
        raise Arango::Error.new err: :impossible_to_connect_with_database,
          data: {"error": e.message}
      end

      if @verbose
        puts "\n===RESPONSE==="
        puts "CODE: #{response.code}"
      end

      case @async
      when :store
        val = response.headers["x-arango-async-id"]
        if @verbose
          puts val
          puts "==============="
        end
        return val
      when true
        puts "===============" if @verbose
        return true
      end

      if skip_parsing
        val = response.parsed_response
        if @verbose
          puts val
          puts "==============="
        end
        return val
      end

      begin
        result = Oj.load(response.parsed_response, mode: :json, symbol_keys: true)
      rescue Exception => e
        raise Arango::Error.new err: :impossible_to_parse_arangodb_response,
          data: {"response": response.parsed_response, "action": action, "url": send_url,
            "request": JSON.pretty_generate(options)}
      end

      if @verbose
        case result
        when Hash, Array
          puts JSON.pretty_generate(result)
        else
          puts "#{result}\n"
        end
        puts "==============="
      end

      case result
      when Hash
        if result[:error]
          raise Arango::ErrorDB.new message: result[:errorMessage],
            code: result[:code], data: result, errorNum: result[:errorNum],
            action: action, url: send_url, request: options
        elsif return_direct_result
          return result
        end
      when Array, NilClass
        return result
      else
        raise Arango::Error.new message: "ArangoRB didn't return a valid result",
          data: {"response": response, "action": action, "url": send_url, "request": JSON.pretty_generate(options)}
      end
      return key.nil? ? result.delete_if{|k,v| k == :error || k == :code} : result[key]
    end

    def download(url:, path:, body: {}, headers: {}, query: {})
      send_url = "#{@base_uri}/"
      send_url += url
      body.delete_if{|k,v| v.nil?}
      query.delete_if{|k,v| v.nil?}
      headers.delete_if{|k,v| v.nil?}
      body = Oj.dump(body, mode: :json)
      options = @options.merge({body: body, query: query, headers: headers, stream_body: true})
      puts "\n#{action} #{send_url}\n" if @verbose
      File.open(path, "w") do |file|
        file.binmode
        HTTParty.post(send_url, options) do |fragment|
          file.write(fragment)
        end
      end
    end
  end
end
