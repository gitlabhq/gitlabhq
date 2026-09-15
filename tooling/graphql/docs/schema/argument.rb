# frozen_string_literal: true

require_relative 'item'
require_relative 'concerns/deprecable'
require_relative 'concerns/typeable'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A single argument on a GraphQL input object, field, or directive.
        class Argument < Item
          include Deprecable
          include Typeable

          attr_reader :default_value

          def initialize(argument)
            super

            @has_default_value = argument.default_value?
            @default_value = render_default_value(argument) if @has_default_value
          end

          def default_value?
            @has_default_value
          end

          private

          def render_default_value(argument)
            node = default_value_node(argument.default_value, argument.type)

            if node.is_a?(::GraphQL::Language::Nodes::AbstractNode)
              ::GraphQL::Language::Printer.new.print(node)
            else
              ::GraphQL::Language.serialize(node)
            end
          end

          # Builds a GraphQL language node for a default value so it prints as a
          # valid GraphQL literal. Mirrors how graphql-ruby renders defaults in
          # the schema definition (SDL), notably rendering enum values unquoted.
          def default_value_node(value, type)
            type = type.of_type if type.kind.non_null?

            if value.nil?
              ::GraphQL::Language::Nodes::NullValue.new(name: 'null')
            elsif type.kind.list?
              value.map { |item| default_value_node(item, type.of_type) }
            elsif type.kind.enum?
              ::GraphQL::Language::Nodes::Enum.new(name: type.coerce_isolated_result(value))
            else
              type.coerce_isolated_result(value)
            end
          end
        end
      end
    end
  end
end
