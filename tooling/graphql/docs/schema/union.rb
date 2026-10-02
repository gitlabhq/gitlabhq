# frozen_string_literal: true

require_relative 'item'
require_relative 'object'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A union type is a value that can be one of several object types.
        #
        # @see https://graphql.org/learn/schema/#union-types
        class Union < Item
          attr_reader :members

          # `members` are the GraphQL object types this union can resolve to.
          def initialize(union, members: [])
            super(union)

            @members = members
              .map { |type| Object.new(type, with_fields: false) }
              .sort_by(&:name)
          end
        end
      end
    end
  end
end
