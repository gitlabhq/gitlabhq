# frozen_string_literal: true

require_relative 'schema/enum'
require_relative 'schema/scalar'

module Tooling
  module Graphql
    module Docs
      class SchemaParser
        attr_reader :enums, :scalars

        def initialize(schema)
          @schema = schema
          @enums = []
          @scalars = []
        end

        def execute
          parse_types

          self
        end

        private

        attr_reader :schema

        def parse_types
          schema.types.each_value do |type|
            next if type.introspection?

            @enums << Schema::Enum.new(type) if type.kind.enum?
            @scalars << Schema::Scalar.new(type) if type.kind.scalar?
          end
        end
      end
    end
  end
end
