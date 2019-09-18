module Arango
  class Request
    def initialize(base_uri:, options:)
      @base_uri = base_uri
      @options = options
    end

    attr_accessor :base_uri, :options

    def request(action, url, body: {}, headers: nil, query: nil, key: nil, keep_null: false)
      # TODO uri safety, '..', etc., maybe arango is guarded? not sure.
      send_url = "#{@base_uri}/"
      send_url += url

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

      options.delete_if{|_,v| v.empty?}

      begin
        response = case action
                   when "GET"
                     options.delete(:body)
                     Typhoeus.get(send_url, options)
                   when "HEAD"
                     options.delete(:body)
                     Typhoeus.head(send_url, options)
                   when "PATCH"
                     Typhoeus.patch(send_url, options)
                   when "POST"
                     Typhoeus.post(send_url, options)
                   when "PUT"
                     Typhoeus.put(send_url, options)
                   when "DELETE"
                     options.delete(:body)
                     Typhoeus.delete(send_url, options)
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
          data: { response: response.response_body, action: action, url: send_url, request: JSON.pretty_generate(options) }
      end

      if !result.is_array? && result.error?
        raise Arango::ErrorDB.new(message: result.error_message, code: result.code, data: result.to_h, error_num: result.error_num,
                                  action: action, url: send_url, request: options)
      end
      key ? result[key] : result
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
