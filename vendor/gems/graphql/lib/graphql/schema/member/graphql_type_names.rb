# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # These constants are interpreted as GraphQL types when defining fields or arguments
      #
      # @example
      #   field :is_draft, Boolean, null: false
      #   field :id, ID, null: false
      #   field :score, Int, null: false
      #
      # @api private
      module GraphQLTypeNames
        Boolean = "Boolean"
        ID = "ID"
        Int = "Int"
      end
    end
  end
end
