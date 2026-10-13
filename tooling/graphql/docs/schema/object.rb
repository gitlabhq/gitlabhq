# frozen_string_literal: true

require_relative 'item'
require_relative 'field'
require_relative 'factory'
require_relative 'interface'

module Tooling
  module Graphql
    module Docs
      module Schema
        # An object type is a GraphQL type with fields.
        #
        # @see https://graphql.org/learn/schema/#object-types-and-fields
        class Object < Item
          attr_reader :fields

          def initialize(object, with_fields: true)
            super(object)

            return unless with_fields

            @fields = object.fields.values.map do |field|
              Field.new(field)
            end
          end

          # The interfaces this object type implements.
          # Returns an empty array for objects that implement no interfaces.
          def implemented_interfaces
            item.interfaces.map { |interface| Interface.new(interface, with_fields: false) }.sort_by(&:name)
          end

          # True when this object type is a Relay edge type.
          def edge?
            item < GraphQL::Types::Relay::BaseEdge
          end

          # True when this object type is a Relay connection type.
          def connection?
            item < GraphQL::Types::Relay::BaseConnection
          end

          # The wrapped node type for a connection or edge, or nil for ordinary
          # object types.
          def node_type
            underlying_node_type = graphql_node_type
            return unless underlying_node_type

            Factory.wrap(underlying_node_type)
          end

          private

          # The underlying GraphQL node type for a connection or edge, or nil for
          # ordinary object types.
          def graphql_node_type
            if connection?
              item.node_type
            elsif edge?
              item.fields['node'].type.unwrap
            end
          end
        end
      end
    end
  end
end
