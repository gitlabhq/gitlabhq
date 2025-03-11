# frozen_string_literal: true
module GraphQL
  module Introspection
    class TypeKindEnum < GraphQL::Schema::Enum
      graphql_name "__TypeKind"
      description "An enum describing what kind of type a given `__Type` is."
      GraphQL::TypeKinds::TYPE_KINDS.each do |type_kind|
        value(type_kind.name, type_kind.description)
      end
      introspection true
    end
  end
end
