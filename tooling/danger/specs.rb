# frozen_string_literal: true

module Tooling
  module Danger
    module Specs
      SPEC_FILES_REGEX = 'spec/'
      EE_PREFIX = 'ee/'
      MATCH_WITH_ARRAY_REGEX = /(?<to>to\(?\s*)(?<matcher>match|eq)(?<expectation>[( ]?\[)/.freeze
      SUGGEST_MR_COMMENT = <<~SUGGEST_COMMENT
      ```suggestion
      %<suggested_line>s
      ```

      If order of the result is not important, please consider using `match_array` to avoid flakiness.
      SUGGEST_COMMENT

      def changed_specs_files(ee: :include)
        changed_files = helper.all_changed_files
        folder_prefix =
          case ee
          when :include
            "(#{EE_PREFIX})?"
          when :only
            EE_PREFIX
          when :exclude
            nil
          end

        changed_files.grep(%r{\A#{folder_prefix}#{SPEC_FILES_REGEX}})
      end

      def add_suggestions_for_match_with_array(filename)
        added_lines = added_line_matching_match_with_array(filename)
        return if added_lines.empty?

        spec_file_lines = project_helper.file_lines(filename)

        added_lines.each_with_object([]) do |added_line, processed_line_numbers|
          line_number = find_line_number(spec_file_lines, added_line.delete_prefix('+'), exclude_indexes: processed_line_numbers)
          processed_line_numbers << line_number
          markdown(format(SUGGEST_MR_COMMENT, suggested_line: spec_file_lines[line_number].gsub(MATCH_WITH_ARRAY_REGEX, '\k<to>match_array\k<expectation>')), file: filename, line: line_number.succ)
        end
      end

      def added_line_matching_match_with_array(filename)
        helper.changed_lines(filename).grep(/\A\+ /).grep(MATCH_WITH_ARRAY_REGEX)
      end

      private

      def find_line_number(file_lines, searched_line, exclude_indexes: [])
        file_lines.each_with_index do |file_line, index|
          next if exclude_indexes.include?(index)
          break index if file_line == searched_line
        end
      end
    end
  end
end
