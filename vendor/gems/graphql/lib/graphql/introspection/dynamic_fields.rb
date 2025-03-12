# frozen_string_literal: true
module GraphQL
  module Introspection
    class DynamicFields < Introspection::BaseObject
      field :__typename, String, "The name of this type", null: false, dynamic_introspection: true

      def __typename
        object.class.graphql_name
      end
    end
  end
end
