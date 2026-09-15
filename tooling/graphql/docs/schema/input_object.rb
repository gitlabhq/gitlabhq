# frozen_string_literal: true

require_relative 'item'
require_relative 'argument'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A GraphQL input object type.
        class InputObject < Item
          attr_reader :arguments

          def initialize(input_object, with_arguments: true)
            super(input_object)

            return unless with_arguments

            @arguments = input_object.arguments.values.map do |argument|
              Argument.new(argument)
            end
          end
        end
      end
    end
  end
end
