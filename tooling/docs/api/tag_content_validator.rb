# frozen_string_literal: true

require 'json_schemer'
require 'pathname'

require_relative 'tag_content'

module Docs
  module Api
    class TagContentValidator
      SCHEMA_FILE = 'type_schema.json'

      Result = Data.define(:schema, :orphan, :description, :checked) do
        def valid?
          schema.empty? && orphan.empty? && description.empty?
        end
      end

      def initialize(tag_content = TagContent.new)
        @tag_content = tag_content
      end

      def validate(declared_slugs)
        Result.new(
          schema: schema_violations,
          orphan: orphan_violations(declared_slugs),
          description: description_violations,
          checked: tag_content.slugs.size
        )
      end

      def json_schema_file
        @json_schema_file ||= File.join(tag_content.tags_dir, SCHEMA_FILE)
      end

      private

      attr_reader :tag_content

      def schema_violations
        tag_content.tag_files.each_with_object({}) do |path, violations|
          errors = schema_validator.validate(tag_content.front_matter_for(path)).to_a

          violations[path] = errors if errors.any?
        end
      end

      def orphan_violations(declared_slugs)
        tag_content.tag_files.reject { |path| declared_slugs.include?(tag_content.slug_for(path)) }
      end

      def description_violations
        tag_content.tag_files.reject { |path| tag_content[tag_content.slug_for(path)].key?('description') }
      end

      def schema_validator
        @schema_validator ||= JSONSchemer.schema(Pathname.new(json_schema_file))
      end
    end
  end
end
