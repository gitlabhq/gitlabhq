# frozen_string_literal: true

require_relative 'scalar'
require_relative 'enum'
require_relative 'input_object'
require_relative 'object'
require_relative 'interface'
require_relative 'temp_undocumented'

module Tooling
  module Graphql
    module Docs
      module Schema
        # Builds the docs schema class matching a GraphQL type.
        module Factory
          # Wraps a GraphQL type in the matching docs schema class. Types without
          # a docs page yet (unions) wrap to TempUndocumented, which the renderer
          # shows unlinked. See https://gitlab.com/gitlab-org/gitlab/-/issues/593121.
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
            else
              TempUndocumented.new(graphql_type)
            end
          end
        end
      end
    end
  end
end
