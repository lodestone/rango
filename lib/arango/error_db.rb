module Arango
  class ErrorDB < Arango::Error
    def initialize(message:, code:, data:, error_num:, action:, url:, request:)
      @message   = message
      @code      = code
      @data      = data
      @error_num = error_num
      @action    = action
      @url       = url
      @request   = request
      super(err: nil, skip_assignment: true)
    end
    attr_reader :action, :code, :data, :error_num, :message, :request, :url

    def to_h
      {
        action: @action,
        url: @url,
        request: @request,
        message: @message,
        code: @code,
        data: @data,
        errorNum: @error_num
      }.delete_if{|k,v| v.nil?}
    end
  end
end
