# frozen_string_literal: true
module GraphQL
  module Introspection
    class DirectiveType < Introspection::BaseObject
      graphql_name "__Directive"
      description "A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document."\
                  "\n\n"\
                  "In some cases, you need to provide options to alter GraphQL's execution behavior "\
                  "in ways field arguments will not suffice, such as conditionally including or "\
                  "skipping a field. Directives provide this by describing additional information "\
                    "to the executor."
      field :name, String, null: false, method: :graphql_name
      field :description, String
      field :locations, [GraphQL::Schema::LateBoundType.new("__DirectiveLocation")], null: false, scope: false
      field :args, [GraphQL::Schema::LateBoundType.new("__InputValue")], null: false, scope: false do
        argument :include_deprecated, Boolean, required: false, default_value: false
      end
      field :on_operation, Boolean, null: false, deprecation_reason: "Use `locations`.", method: :on_operation?
      field :on_fragment, Boolean, null: false, deprecation_reason: "Use `locations`.", method: :on_fragment?
      field :on_field, Boolean, null: false, deprecation_reason: "Use `locations`.", method: :on_field?

      field :is_repeatable, Boolean, method: :repeatable?

      def args(include_deprecated:)
        args = @context.types.arguments(@object)
        args = args.reject(&:deprecation_reason) unless include_deprecated
        args
      end
    end
  end
end
