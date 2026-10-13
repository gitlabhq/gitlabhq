# frozen_string_literal: true

require_relative 'item'
require_relative 'field'
require_relative 'object'

module Tooling
  module Graphql
    module Docs
      module Schema
        # An interface type is a set of fields that object types can implement.
        #
        # @see https://graphql.org/learn/schema/#interfaces
        class Interface < Item
          attr_reader :fields, :implementations

          # `implementations` are the GraphQL object types that implement this interface.
          def initialize(interface, implementations: [], with_fields: true)
            super(interface)

            @implementations = implementations
              .map { |type| Object.new(type, with_fields: false) }
              .sort_by(&:name)

            return unless with_fields

            @fields = interface.fields.values.map do |field|
              Field.new(field)
            end
          end
        end
      end
    end
  end
end
