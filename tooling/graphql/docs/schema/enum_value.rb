# frozen_string_literal: true

require_relative 'item'
require_relative 'concerns/deprecable'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A single value within a GraphQL enum type.
        class EnumValue < Item
          include Deprecable

          attr_reader :value

          def initialize(enum_value)
            super

            @value = enum_value.value
          end
        end
      end
    end
  end
end
