# frozen_string_literal: true

require_relative 'schema_parser'
require_relative 'renderer'

module Tooling
  module Graphql
    module Docs
      class Compiler
        OUTPUT_DIR = Rails.root.join('doc/api/graphql/reference/experimental')

        CompiledDoc = Struct.new(:filename, :doc, keyword_init: true)

        def initialize(schema: GitlabSchema)
          @schema = schema
        end

        def execute
          parsed_schema = SchemaParser.new(schema).execute

          [
            compile(:index, filename: '_index.md'),
            compile(:enums, parsed_schema.enums),
            compile(:input_objects, parsed_schema.input_objects),
            compile(:scalars, parsed_schema.scalars),
            compile(:directives, parsed_schema.directives)
          ]
        end

        private

        attr_reader :schema

        def compile(type, data = nil, filename: "#{type}.md")
          locals = data.nil? ? {} : { type => data }

          doc = Renderer.new(
            template: type,
            locals: locals
          ).execute

          CompiledDoc.new(
            filename: File.join(OUTPUT_DIR, filename),
            doc: "#{doc}\n"
          )
        end
      end
    end
  end
end
