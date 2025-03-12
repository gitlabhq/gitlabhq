# frozen_string_literal: true
module GraphQL
  # This error is raised when `Types::Int` is given an input value outside of 32-bit integer range.
  #
  # For really big integer values, consider `GraphQL::Types::BigInt`
  #
  # @see GraphQL::Types::Int which raises this error
  class IntegerDecodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be decoded
    attr_reader :integer_value

    def initialize(value)
      @integer_value = value
      super("Integer out of bounds: #{value}. \nConsider using GraphQL::Types::BigInt instead.")
    end
  end
end
