# frozen_string_literal: true
module GraphQL
  class UnauthorizedEnumValueError < GraphQL::UnauthorizedError
    # @return [GraphQL::Schema::EnumValue] The value whose `#authorized?` check returned false
    attr_accessor :enum_value

    def initialize(type:, context:, enum_value:)
      @enum_value = enum_value
      message ||= "#{enum_value.path} failed authorization"
      super(message, object: enum_value.value, type: type, context: context)
    end
  end
end
