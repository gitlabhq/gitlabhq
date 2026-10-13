# frozen_string_literal: true

require_relative 'item'
require_relative 'argument'
require_relative 'concerns/deprecable'
require_relative 'concerns/typeable'
require_relative 'factory'

module Tooling
  module Graphql
    module Docs
      module Schema
        # A field is a queryable property on an object.
        #
        # @see https://graphql.org/learn/queries/#fields
        class Field < Item
          include Deprecable
          include Typeable

          # The standard Relay pagination arguments, common to all connection
          # fields. These are documented once in the connections section rather
          # than repeated on every connection field.
          PAGINATION_ARGUMENTS = %w[after before first last].freeze

          attr_reader :arguments

          def initialize(field)
            super

            @arguments = field.arguments.values.map do |argument|
              Argument.new(argument)
            end
          end

          def connection?
            item.connection?
          end

          # Arguments excluding the standard pagination arguments for
          # connection fields, which are documented in one place instead.
          def arguments_without_pagination
            return arguments unless connection?

            arguments.reject { |argument| PAGINATION_ARGUMENTS.include?(argument.name) }
          end
        end
      end
    end
  end
end
