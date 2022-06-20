# frozen_string_literal: true

module Graphql
  class FieldInspection
    def initialize(field)
      @field = field
    end

    def nested_fields?
      !scalar? && !enum?
    end

    def scalar?
      type.kind.scalar?
    end

    def enum?
      type.kind.enum?
    end

    def type
      @type ||= begin
        field_type = @field.type

        # The type could be nested. For example `[GraphQL::Types::String]`:
        # - List
        # - String!
        # - String
        field_type = field_type.of_type while field_type.respond_to?(:of_type)

        field_type
      end
    end
  end
end
