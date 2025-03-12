# frozen_string_literal: true
module GraphQL
  # This error is raised when `Types::ISO8601Duration` is asked to return a value
  # that cannot be parsed as an ISO8601-formatted duration by ActiveSupport::Duration.
  #
  # @see GraphQL::Types::ISO8601Duration which raises this error
  class DurationEncodingError < GraphQL::RuntimeTypeError
    # The value which couldn't be encoded
    attr_reader :duration_value

    def initialize(value)
      @duration_value = value
      super("Duration cannot be parsed: #{value}. \nDuration must be an ISO8601-formatted duration.")
    end
  end
end
