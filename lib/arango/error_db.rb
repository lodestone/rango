module Arango
  class ErrorDB < Arango::Error
    def initialize(message:, code:, data:, errorNum:, action:, url:, request:)
      @message  = message
      @code     = code
      @data     = data
      @errorNum = errorNum
      @action   = action
      @url      = url
      @request  = request
      super(err: nil, skip_assignment: true)
    end
    attr_reader :message, :code, :data, :errorNum, :action, :url, :request

    def to_h
      {
        action: @action,
        url: @url,
        request: @request,
        message: @message,
        code: @code,
        data: @data,
        errorNum: @errorNum
      }.delete_if{|k,v| v.nil?}
    end
  end
end
