# frozen_string_literal: true

require_relative 'item'
require_relative 'argument'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A GraphQL directive.
        #
        # @see https://graphql.org/learn/queries/#directives
        class Directive < Item
          attr_reader :arguments, :locations

          def initialize(directive)
            super

            @arguments = directive.arguments.values.map do |argument|
              Argument.new(argument)
            end

            @locations = directive.locations.map(&:to_s).sort
            @repeatable = directive.repeatable?
          end

          def repeatable?
            @repeatable
          end
        end
      end
    end
  end
end
