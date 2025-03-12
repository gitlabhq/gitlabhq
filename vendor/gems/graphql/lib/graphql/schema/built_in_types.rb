# frozen_string_literal: true
module GraphQL
  class Schema
    BUILT_IN_TYPES = {
      "Int" => GraphQL::Types::Int,
      "String" => GraphQL::Types::String,
      "Float" => GraphQL::Types::Float,
      "Boolean" => GraphQL::Types::Boolean,
      "ID" => GraphQL::Types::ID,
    }
  end
end
