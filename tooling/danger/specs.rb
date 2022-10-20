# frozen_string_literal: true

module Tooling
  module Danger
    module Specs
      SPEC_FILES_REGEX = 'spec/'
      EE_PREFIX = 'ee/'
      MATCH_WITH_ARRAY_REGEX = /(?<to>to\(?\s*)(?<matcher>match|eq)(?<expectation>[( ]?\[[^\]]+)/.freeze
      MATCH_WITH_ARRAY_REPLACEMENT = '\k<to>match_array\k<expectation>'

      PROJECT_FACTORIES = %w[
        :project
        :project_empty_repo
        :forked_project_with_submodules
        :project_with_design
      ].freeze

      PROJECT_FACTORY_REGEX = /
        ^\+?                                 # Start of the line, which may or may not have a `+`
        (?<head>\s*)                         # 0-many leading whitespace captured in a group named head
        let!?                                # Literal `let` which may or may not end in `!`
        (?<tail>                             # capture group named tail
          \([^)]+\)                          # Two parenthesis with any non-parenthesis characters between them
          \s*\{\s*                           # Opening curly brace surrounded by 0-many whitespace characters
          create\(                           # literal
          (?:#{PROJECT_FACTORIES.join('|')}) # Any of the project factory names
          \W                                 # Non-word character, avoid matching factories like :project_authorization
        )                                    # end capture group named tail
      /x.freeze

      PROJECT_FACTORY_REPLACEMENT = '\k<head>let_it_be\k<tail>'
      SUGGESTION_MARKDOWN = <<~SUGGESTION_MARKDOWN
      ```suggestion
      %<suggested_line>s
      ```
      SUGGESTION_MARKDOWN

      MATCH_WITH_ARRAY_SUGGESTION = <<~SUGGEST_COMMENT
      If order of the result is not important, please consider using `match_array` to avoid flakiness.
      SUGGEST_COMMENT

      PROJECT_FACTORY_SUGGESTION = <<~SUGGEST_COMMENT
      Project creations are very slow. Use `let_it_be`, `build` or `build_stubbed` if possible.
      See [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#optimize-factory-usage)
      for background information and alternative options.
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
        add_suggestion(
          filename,
          MATCH_WITH_ARRAY_REGEX,
          MATCH_WITH_ARRAY_REPLACEMENT,
          MATCH_WITH_ARRAY_SUGGESTION
        )
      end

      def add_suggestions_for_project_factory_usage(filename)
        add_suggestion(
          filename,
          PROJECT_FACTORY_REGEX,
          PROJECT_FACTORY_REPLACEMENT,
          PROJECT_FACTORY_SUGGESTION
        )
      end

      private

      def added_lines_matching(filename, regex)
        helper.changed_lines(filename).grep(/\A\+ /).grep(regex)
      end

      def add_suggestion(filename, regex, replacement, comment_text)
        added_lines = added_lines_matching(filename, regex)
        return if added_lines.empty?

        spec_file_lines = project_helper.file_lines(filename)

        added_lines.each_with_object([]) do |added_line, processed_line_numbers|
          line_number = find_line_number(spec_file_lines, added_line.delete_prefix('+'), exclude_indexes: processed_line_numbers)
          next unless line_number

          processed_line_numbers << line_number
          text = format(comment(comment_text), suggested_line: spec_file_lines[line_number].gsub(regex, replacement))
          markdown(text, file: filename, line: line_number.succ)
        end
      end

      def comment(comment_text)
        <<~COMMENT_BODY.chomp
        #{SUGGESTION_MARKDOWN}
        #{comment_text}
        COMMENT_BODY
      end

      def find_line_number(file_lines, searched_line, exclude_indexes: [])
        _, index = file_lines.each_with_index.find do |file_line, index|
          file_line == searched_line && !exclude_indexes.include?(index)
        end

        index
      end
    end
  end
end
