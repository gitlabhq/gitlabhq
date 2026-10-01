# frozen_string_literal: true

require_relative 'schema/directive'
require_relative 'schema/enum'
require_relative 'schema/input_object'
require_relative 'schema/interface'
require_relative 'schema/object'
require_relative 'schema/scalar'

module Tooling
  module Graphql
    module Docs
      class SchemaParser
        # An edge type is "standard" if it has only the base cursor and node
        # fields. Standard edges are documented once in the standard connection
        # fields section rather than repeated on the objects page.
        STANDARD_EDGE_FIELDS = %w[cursor node].freeze

        attr_reader :directives, :enums, :input_objects, :interfaces, :objects, :scalars

        def initialize(schema)
          @schema = schema
          @directives = []
          @enums = []
          @input_objects = []
          @interfaces = []
          @objects = []
          @scalars = []
        end

        def execute
          parse_types
          parse_directives

          self
        end

        private

        attr_reader :schema

        def parse_types
          schema.types.each_value do |type|
            next if type.introspection?
            next if [root_query, root_mutation, root_subscription].include?(type)

            if type.kind.object? && !standard_edge?(type) && !mutation_payload?(type)
              @objects << Schema::Object.new(type)
            end

            @enums << Schema::Enum.new(type) if type.kind.enum?
            @input_objects << Schema::InputObject.new(type) if type.kind.input_object?
            @scalars << Schema::Scalar.new(type) if type.kind.scalar?

            if type.kind.interface?
              @interfaces << Schema::Interface.new(type, implementations: schema.possible_types(type))
            end
          end
        end

        def parse_directives
          @directives = schema.directives.values.map do |directive|
            Schema::Directive.new(directive)
          end
        end

        def mutation_payload_names
          @mutation_payload_names ||=
            if root_mutation
              root_mutation.fields.values.map { |field| field.type.unwrap.graphql_name }.to_set
            else
              Set.new
            end
        end

        def mutation_payload?(type)
          mutation_payload_names.include?(type.graphql_name)
        end

        def standard_edge?(type)
          return false unless type < GraphQL::Types::Relay::BaseEdge

          type.fields.keys.sort == STANDARD_EDGE_FIELDS
        end

        def root_query
          @root_query ||= schema.root_type_for_operation('query')
        end

        def root_mutation
          @root_mutation ||= schema.root_type_for_operation('mutation')
        end

        def root_subscription
          @root_subscription ||= schema.root_type_for_operation('subscription')
        end
      end
    end
  end
end
