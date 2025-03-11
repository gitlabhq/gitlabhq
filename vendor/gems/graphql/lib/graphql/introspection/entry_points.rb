# frozen_string_literal: true
module GraphQL
  module Introspection
    class EntryPoints < Introspection::BaseObject
      field :__schema, GraphQL::Schema::LateBoundType.new("__Schema"), "This GraphQL schema", null: false, dynamic_introspection: true
      field :__type, GraphQL::Schema::LateBoundType.new("__Type"), "A type in the GraphQL system", dynamic_introspection: true do
        argument :name, String
      end

      def __schema
        # Apply wrapping manually since this field isn't wrapped by instrumentation
        schema = context.schema
        schema_type = schema.introspection_system.types["__Schema"]
        schema_type.wrap(schema, context)
      end

      def __type(name:)
        if context.types.reachable_type?(name) && (type = context.types.type(name))
          type
        elsif (type = context.schema.extra_types.find { |t| t.graphql_name == name })
          type
        else
          nil
        end
      end
    end
  end
end
