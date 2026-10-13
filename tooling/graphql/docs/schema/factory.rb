# frozen_string_literal: true

require_relative 'scalar'
require_relative 'enum'
require_relative 'input_object'
require_relative 'object'
require_relative 'interface'
require_relative 'union'

module Tooling
  module Graphql
    module Docs
      module Schema
        # Builds the docs schema class matching a GraphQL type.
        module Factory
          UnknownKindError = Class.new(StandardError)

          # Wraps a GraphQL type in the matching docs schema class. Raises for a
          # kind without a docs class, so a new kind fails loudly at compile time.
          def self.wrap(graphql_type)
            if graphql_type.kind.scalar?
              Scalar.new(graphql_type)
            elsif graphql_type.kind.object?
              Object.new(graphql_type, with_fields: false)
            elsif graphql_type.kind.enum?
              Enum.new(graphql_type)
            elsif graphql_type.kind.input_object?
              InputObject.new(graphql_type, with_arguments: false)
            elsif graphql_type.kind.interface?
              Interface.new(graphql_type, with_fields: false)
            elsif graphql_type.kind.union?
              Union.new(graphql_type)
            else
              raise UnknownKindError, "No docs schema class for GraphQL kind #{graphql_type.kind.name}"
            end
          end
        end
      end
    end
  end
end
