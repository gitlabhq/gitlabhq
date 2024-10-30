# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module IgnoredModelColumns
      include ::Tooling::Danger::Suggestor

      METHODS = %w[remove_column cleanup_concurrent_column_rename cleanup_conversion_of_integer_to_bigint].freeze
      MIGRATION_FILES_REGEX = %r{^db/(post_)?migrate}
      MIGRATION_METHODS_REGEX = /^\+\s*(.*\.)?(#{METHODS.join('|')})[(\s]/
      UP_METHOD_REGEX = /^.+(def\sup)/
      END_METHOD_REGEX = /^.+(end)/
      DOC_URL = "https://docs.gitlab.com/ee/development/database/avoiding_downtime_in_migrations.html"

      COMMENT = <<~COMMENT.freeze
        Column operations, like [dropping](#{DOC_URL}#dropping-columns), [renaming](#{DOC_URL}#renaming-columns) or
        [primary key conversion](#{DOC_URL}#migrating-integer-primary-keys-to-bigint), require columns to be ignored in
        the model. This step is necessary because Rails caches the columns and re-uses it in various places across the
        application. Please ensure that columns are properly ignored in the model.
      COMMENT

      def add_comment_for_ignored_model_columns
        migration_files.each do |filename|
          add_suggestion(filename: filename, regex: MIGRATION_METHODS_REGEX, comment_text: COMMENT)
        end
      end

      private

      # This method was overwritten to make use of +up_method_lines+.
      # It's necessary to only match lines that are inside the +up+ block in a migration file.
      #
      # @return [Integer, Nil] the line number - only if the line is from within a +up+ method
      def find_line_number(file_lines, searched_line, exclude_indexes: [])
        lines_to_search = up_method_lines(file_lines)

        _, index = file_lines.each_with_index.find do |file_line, index|
          next unless lines_to_search.include?(index)

          file_line == searched_line && !exclude_indexes.include?(index)
        end

        index
      end

      # Return the line numbers from within the up method
      #
      # @example
      #         line 0 def up
      #         line 1   cleanup_conversion_of_integer_to_bigint():my_table, :my_column)
      #         line 2   remove_column(:my_table, :my_column)
      #         line 3   other_method
      #         line 4 end
      #
      #         => [1, 2, 3]
      def up_method_lines(file_lines)
        capture_up_block = false
        up_method_content_lines = []

        file_lines.each_with_index do |content, line_number|
          capture_up_block = false if capture_up_block && END_METHOD_REGEX.match?(content)
          up_method_content_lines << line_number if capture_up_block
          capture_up_block = true if UP_METHOD_REGEX.match?(content)
        end

        up_method_content_lines
      end

      def migration_files
        helper.all_changed_files.grep(MIGRATION_FILES_REGEX)
      end
    end
  end
end
