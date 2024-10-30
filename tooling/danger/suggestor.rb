# frozen_string_literal: true

module Tooling
  module Danger
    module Suggestor
      # For file lines matching `regex` adds suggestion `replacement` with `comment_text` added.
      def add_suggestion(filename:, regex:, replacement: nil, comment_text: nil, exclude: nil, once_per_file: false)
        added_lines = added_lines_matching(filename, regex)

        return if added_lines.empty?

        file_lines = project_helper.file_lines(filename)

        added_lines.each_with_object([]) do |added_line, processed_line_numbers|
          break if once_per_file && processed_line_numbers.any?

          line_number = find_line_number(file_lines, added_line.delete_prefix('+'),
            exclude_indexes: processed_line_numbers)

          next unless line_number
          next if !exclude.nil? && added_line.include?(exclude)

          processed_line_numbers << line_number

          if replacement
            suggestion_text = file_lines[line_number]
            suggestion_text = suggestion_text.gsub(regex, replacement)
          end

          markdown(comment(comment_text, suggestion_text), file: filename, line: line_number.succ)
        end
      end

      private

      def added_lines_matching(filename, regex)
        helper.changed_lines(filename).grep(/\A\+( )?/).grep(regex)
      end

      def find_line_number(file_lines, searched_line, exclude_indexes: [])
        _, index = file_lines.each_with_index.find do |file_line, index|
          file_line == searched_line && !exclude_indexes.include?(index)
        end

        index
      end

      def comment(comment_text = nil, suggested_line = nil)
        if suggested_line
          suggestion_text = <<~SUGGESTION
            ```suggestion
            %<suggested_line>s
            ```
          SUGGESTION
        end

        comment_body = <<~COMMENT_BODY.chomp
        #{suggestion_text}
        #{comment_text}
        COMMENT_BODY

        format(comment_body.chomp, suggested_line: suggested_line)
      end
    end
  end
end
