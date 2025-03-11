# frozen_string_literal: true
module GraphQL
  # This error is raised when `Types::ISO8601Date` is asked to return a value
  # that cannot be parsed to a Ruby Date.
  #
  # @see GraphQL::Types::ISO8601Date which raises this error
  class DateEncodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be encoded
    attr_reader :date_value

    def initialize(value)
      @date_value = value
      super("Date cannot be parsed: #{value}. \nDate must be be able to be parsed as a Ruby Date object.")
    end
  end
end
