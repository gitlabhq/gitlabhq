# frozen_string_literal: true
module GraphQL
  class StringEncodingError < GraphQL::RuntimeTypeError
    attr_reader :string, :field, :path
    def initialize(str, context:)
      @string = str
      @field = context[:current_field]
      @path = context[:current_path]
      message = "String #{str.inspect} was encoded as #{str.encoding}".dup
      if @path
        message << " @ #{@path.join(".")}"
      end
      if @field
        message << " (#{@field.path})"
      end
      message << ". GraphQL requires an encoding compatible with UTF-8."
      super(message)
    end
  end
end
