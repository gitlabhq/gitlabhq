# frozen_string_literal: true
module GraphQL
  class Schema
    class Directive < GraphQL::Schema::Member
      class Deprecated < GraphQL::Schema::Directive
        description "Marks an element of a GraphQL schema as no longer supported."
        locations(GraphQL::Schema::Directive::FIELD_DEFINITION, GraphQL::Schema::Directive::ENUM_VALUE, GraphQL::Schema::Directive::ARGUMENT_DEFINITION, GraphQL::Schema::Directive::INPUT_FIELD_DEFINITION)

        reason_description = "Explains why this element was deprecated, usually also including a "\
        "suggestion for how to access supported similar data. Formatted "\
        "in [Markdown](https://daringfireball.net/projects/markdown/)."

        argument :reason, String, reason_description, default_value: Directive::DEFAULT_DEPRECATION_REASON, required: false
        default_directive true
      end
    end
  end
end
