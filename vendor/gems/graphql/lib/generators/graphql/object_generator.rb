# frozen_string_literal: true
require 'generators/graphql/type_generator'
require 'generators/graphql/field_extractor'

module Graphql
  module Generators
    # Generate an object type by name,
    # with the specified fields.
    #
    # ```
    # rails g graphql:object PostType name:String!
    # ```
    #
    # Add the Node interface with `--node`.
    class ObjectGenerator < TypeGeneratorBase
      desc "Create a GraphQL::ObjectType with the given name and fields." \
      "If the given type name matches an existing ActiveRecord model, the generated type will automatically include fields for the models database columns."
      source_root File.expand_path('../templates', __FILE__)
      include FieldExtractor

      class_option :node,
                   type: :boolean,
                   default: false,
                   desc: "Include the Relay Node interface"

      def self.normalize_type_expression(type_expression, mode:, null: true)
        case type_expression.camelize
        when "Text", "Citext"
          ["String", null]
        when "Decimal"
          ["Float", null]
        when "DateTime", "Datetime"
          ["GraphQL::Types::ISO8601DateTime", null]
        when "Date"
          ["GraphQL::Types::ISO8601Date", null]
        when "Json", "Jsonb", "Hstore"
          ["GraphQL::Types::JSON", null]
        else
          super
        end
      end

      private

      def graphql_type
        "object"
      end
    end
  end
end
