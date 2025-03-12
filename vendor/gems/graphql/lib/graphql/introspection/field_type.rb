# frozen_string_literal: true
module GraphQL
  module Introspection
    class FieldType < Introspection::BaseObject
      graphql_name "__Field"
      description "Object and Interface types are described by a list of Fields, each of which has "\
                  "a name, potentially a list of arguments, and a return type."
      field :name, String, null: false
      field :description, String
      field :args, [GraphQL::Schema::LateBoundType.new("__InputValue")], null: false, scope: false do
        argument :include_deprecated, Boolean, required: false, default_value: false
      end
      field :type, GraphQL::Schema::LateBoundType.new("__Type"), null: false
      field :is_deprecated, Boolean, null: false
      field :deprecation_reason, String

      def is_deprecated
        !!@object.deprecation_reason
      end

      def args(include_deprecated:)
        args = @context.types.arguments(@object)
        args = args.reject(&:deprecation_reason) unless include_deprecated
        args
      end
    end
  end
end
