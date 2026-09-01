# frozen_string_literal: true

require_relative 'schema/directive'
require_relative 'schema/enum'
require_relative 'schema/input_object'
require_relative 'schema/scalar'

module Tooling
  module Graphql
    module Docs
      class SchemaParser
        attr_reader :directives, :enums, :input_objects, :scalars

        def initialize(schema)
          @schema = schema
          @directives = []
          @enums = []
          @input_objects = []
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

            @enums << Schema::Enum.new(type) if type.kind.enum?
            @input_objects << Schema::InputObject.new(type) if type.kind.input_object?
            @scalars << Schema::Scalar.new(type) if type.kind.scalar?
          end
        end

        def parse_directives
          @directives = schema.directives.values.map do |directive|
            Schema::Directive.new(directive)
          end
        end
      end
    end
  end
end
