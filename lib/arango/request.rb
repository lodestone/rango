module Arango
  class Request
    def initialize(base_uri:, options:)
      @base_uri = base_uri
      @options = options
    end

    attr_accessor :base_uri, :options

    def request(get: nil, head: nil, patch: nil, post: nil, put: nil, delete: nil,
                db: nil, body: {}, headers: nil, query: nil, key: nil, keep_null: false, block: nil)
      # TODO uri safety, '..', etc., maybe arango is guarded? not sure.

      if body.class == Hash
        body.delete_if{|_,v| v.nil?} unless keep_null
        body = Oj.dump(body, mode: :json) unless body.nil?
      end
      options = @options.merge({ body: body })

      if query
        query.delete_if{|_,v| v.nil?}
        options[:params] = query
      end

      if headers
        headers.delete_if{|_,v| v.nil?}
        options[:headers].merge!(headers)
      end

      options.delete_if{|_,v| v.nil? || v.empty?}

      dbcontext = db ? "_db/#{db}/" : nil

      begin
        response = if get
                     options.delete(:body)
                     Typhoeus.get("#{@base_uri}/#{dbcontext}#{get}", options)
                   elsif head
                     options.delete(:body)
                     Typhoeus.head("#{@base_uri}/#{dbcontext}#{head}", options)
                   elsif patch then Typhoeus.patch("#{@base_uri}/#{dbcontext}#{patch}", options)
                   elsif post then Typhoeus.post("#{@base_uri}/#{dbcontext}#{post}", options)
                   elsif put then Typhoeus.put("#{@base_uri}/#{dbcontext}#{put}", options)
                   elsif delete
                     options.delete(:body)
                     Typhoeus.delete("#{@base_uri}/#{dbcontext}#{delete}", options)
                   end
      rescue Exception => e
        raise Arango::Error.new err: :impossible_to_connect_with_database, data: { error: e.message }
      end

      if headers && headers.key?("Content-Type") && headers["Content-Type"].start_with?("multipart/form-data")
        return response.response_body
      end

      begin
        json_result = unless response.response_body.empty?
                        Oj.load(response.response_body, mode: :json, symbol_keys: true)
                      else
                        {}
                      end
        result = Arango::Result.new(json_result)
        result.response_code = response.response_code
      rescue Exception => e
        raise Arango::Error.new err: :impossible_to_parse_arangodb_response,
          data: { response: response.response_body, request: JSON.pretty_generate(options) }
      end

      if !result.is_array? && result.error?
        raise Arango::ErrorDB.new(message: result.error_message, code: result.code, data: result.to_h, error_num: result.error_num, request: options)
      end
      if block
        block.call(key ? result[key] : result)
      else
        key ? result[key] : result
      end
    end

    def download(url:, path:, body: {}, headers: {}, query: {})
      send_url = "#{@base_uri}/"
      send_url += url
      body.delete_if{|_,v| v.nil?}
      query.delete_if{|_,v| v.nil?}
      headers.delete_if{|_,v| v.nil?}
      body = Oj.dump(body, mode: :json)
      options = @options.merge({body: body, query: query, headers: headers, stream_body: true})
      File.open(path, "w") do |file|
        file.binmode
        Typhoeus.post(send_url, options) do |fragment|
          file.write(fragment)
        end
      end
    end
  end
end
