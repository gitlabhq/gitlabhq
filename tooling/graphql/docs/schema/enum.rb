# frozen_string_literal: true

require_relative 'item'
require_relative 'enum_value'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A GraphQL enum type.
        class Enum < Item
          attr_reader :values

          def initialize(enum)
            super

            @values = enum.enum_values.map do |value|
              EnumValue.new(value)
            end
          end
        end
      end
    end
  end
end
