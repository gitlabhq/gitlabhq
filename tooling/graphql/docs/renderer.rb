# frozen_string_literal: true

require_relative 'helper'

module Tooling
  module Graphql
    module Docs
      # Gitlab renderer for graphql-docs.
      # Uses HAML templates to parse markdown and generate .md files.
      # It uses graphql-docs helpers and schema parser, more information in https://github.com/gjtorikian/graphql-docs.
      #
      # Arguments:
      #   schema - the GraphQL schema definition. For GitLab should be: GitlabSchema
      #   output_dir: The folder where the markdown files will be saved
      #   template: The path of the haml template to be parsed
      class Renderer
        include Tooling::Graphql::Docs::Helper

        attr_reader :schema

        def initialize(schema, output_dir:, template:)
          @output_dir = output_dir
          @template = template
          @layout = Haml::Engine.new(File.read(template))
          @parsed_schema = GraphQLDocs::Parser.new(schema.graphql_definition, {}).parse
          @schema = schema
          @seen = Set.new
        end

        def contents
          # Render and remove an extra trailing new line
          @contents ||= @layout.render(self).sub!(/\n(?=\Z)/, '')
        end

        def write
          filename = File.join(@output_dir, 'index.md')

          FileUtils.mkdir_p(@output_dir)
          File.write(filename, contents)
        end

        private

        def seen_type?(name)
          @seen.include?(name)
        end

        def seen_type!(name)
          @seen << name
        end
      end
    end
  end
end
