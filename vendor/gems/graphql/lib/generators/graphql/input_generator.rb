# frozen_string_literal: true
require 'generators/graphql/type_generator'
require 'generators/graphql/field_extractor'

module Graphql
  module Generators
    # Generate an input type by name,
    # with the specified fields.
    #
    # ```
    # rails g graphql:object PostType name:string!
    # ```
    class InputGenerator < TypeGeneratorBase
      desc "Create a GraphQL::InputObjectType with the given name and fields"
      source_root File.expand_path('../templates', __FILE__)
      include FieldExtractor

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
        "input"
      end

      def type_ruby_name
        super.gsub(/Type\z/, "InputType")
      end

      def type_file_name
        super.gsub(/_type\z/, "_input_type")
      end
    end
  end
end
