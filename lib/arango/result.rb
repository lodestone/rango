module Arango
  class Result
    def initialize(result)
      @result = result ? result : {}
      @is_array = @result.class == Array
    end

    # standard fields
    def code
      @result[:code]
    end

    def error
      @result[:error]
    end

    def error_message
      @result[:errorMessage]
    end
    alias errorMessage error_message

    def error_num
      @result[:errorNum]
    end
    alias errorNum error_num

    # access to all other fields
    def [](field_name_or_index)
      return @result[field_name_or_index] if @is_array
      field_name_y = field_name_or_index.to_sym
      return @result[field_name_y] if @result.key?(field_name_y)
      field_name_s = field_name_or_index.to_s
      field_name_lcy = field_name_s.camelize(:lower).to_sym
      return @result[field_name_lcy] if @result.key?(field_name_lcy)
      field_name_ucy = field_name_s.camelize(:upper).to_sym
      return @result[field_name_ucy] if @result.key?(field_name_ucy)
      nil
    end

    def method_missing(field_name)
      self[field_name]
    end

    # convenience
    def delete_if(*args, &block)
      @result.delete_if(*args, &block)
    end

    def empty?
      @result.empty?
    end

    def is_array?
      @is_array
    end

    def map(*args, &block)
      @result.map(*args, &block)
    end

    def raw_result
      @result
    end

    def to_h
      @result unless @is_array
    end

    def to_a
      @result if @is_array
    end
  end
end