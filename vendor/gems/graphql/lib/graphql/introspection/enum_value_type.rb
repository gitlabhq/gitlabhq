# frozen_string_literal: true
module GraphQL
  module Introspection
    class EnumValueType < Introspection::BaseObject
      graphql_name "__EnumValue"
      description "One possible value for a given Enum. Enum values are unique values, not a "\
                  "placeholder for a string or numeric value. However an Enum value is returned in "\
                  "a JSON response as a string."
      field :name, String, null: false
      field :description, String
      field :is_deprecated, Boolean, null: false
      field :deprecation_reason, String

      def name
        object.graphql_name
      end

      def is_deprecated
        !!@object.deprecation_reason
      end
    end
  end
end
