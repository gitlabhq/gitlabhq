# frozen_string_literal: true

require_relative 'scalar'
require_relative 'enum'
require_relative 'input_object'
require_relative 'temp_undocumented'

module Tooling
  module Graphql
    module Docs
      module Schema
        # Builds the docs schema class matching a GraphQL type.
        module Factory
          # Wraps a GraphQL type in the matching docs schema class. Types without
          # a docs page yet (interfaces, unions) wrap to TempUndocumented, which
          # the renderer shows unlinked.
          def self.wrap(graphql_type)
            if graphql_type.kind.scalar?
              Scalar.new(graphql_type)
            elsif graphql_type.kind.object?
              # Required here rather than at the top to avoid a load-time cycle:
              # Object -> Field -> Typeable -> this factory.
              require_relative 'object'
              Object.new(graphql_type, with_fields: false)
            elsif graphql_type.kind.enum?
              Enum.new(graphql_type)
            elsif graphql_type.kind.input_object?
              InputObject.new(graphql_type, with_arguments: false)
            else
              TempUndocumented.new(graphql_type)
            end
          end
        end
      end
    end
  end
end
