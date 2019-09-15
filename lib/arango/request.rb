module Arango
  class Request
    def initialize(return_output:, base_uri:, options:)
      @return_output = return_output
      @base_uri = base_uri
      @options = options
    end

    attr_accessor :base_uri, :options, :return_output

    def request(action, url, body: {}, headers: {}, query: {}, key: nil, skip_to_json: false, keep_null: false,
                skip_parsing: false)
      # TODO uri safety, '..', etc., maybe arango is guarded? not sure.
      send_url = "#{@base_uri}/"
      send_url += url

      if body.is_a?(Hash)
        body.delete_if{|_,v| v.nil?} unless keep_null
      end
      query.delete_if{|_,v| v.nil?}
      headers.delete_if{|_,v| v.nil?}
      options = @options.merge({ body: body, params: query })
      options[:headers].merge!(headers)

      if %w[GET HEAD DELETE].include?(action)
        options.delete(:body)
      end

      if !skip_to_json && !options[:body].nil?
        options[:body] = Oj.dump(options[:body], mode: :json)
      end
      options.delete_if{|_,v| v.empty?}

      begin
        response = case action
        when "GET"
          Typhoeus.get(send_url, options)
        when "HEAD"
          Typhoeus.head(send_url, options)
        when "PATCH"
          Typhoeus.patch(send_url, options)
        when "POST"
          Typhoeus.post(send_url, options)
        when "PUT"
          Typhoeus.put(send_url, options)
        when "DELETE"
          Typhoeus.delete(send_url, options)
        end
      rescue Exception => e
        raise Arango::Error.new err: :impossible_to_connect_with_database,
          data: {error: e.message}
      end

      if skip_parsing
        val = response.response_body
        return val
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

      if !result.is_array? && result[:error]
        raise Arango::ErrorDB.new(message: result[:errorMessage], code: result[:code], data: result, error_num: result[:errorNum],
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
