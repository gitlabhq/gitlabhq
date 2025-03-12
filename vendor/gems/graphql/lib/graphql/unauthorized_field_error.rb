# frozen_string_literal: true
module GraphQL
  class UnauthorizedFieldError < GraphQL::UnauthorizedError
    # @return [Field] the field that failed the authorization check
    attr_accessor :field

    def initialize(message = nil, object: nil, type: nil, context: nil, field: nil)
      if message.nil? && [field, type].any?(&:nil?)
        raise ArgumentError, "#{self.class.name} requires either a message or keywords"
      end

      @field = field
      message ||= begin
        if object
          "An instance of #{object.class} failed #{type.name}'s authorization check on field #{field.name}"
        else
          "Failed #{type.name}'s authorization check on field #{field.name}"
        end
      end
      super(message, object: object, type: type, context: context)
    end
  end
end
