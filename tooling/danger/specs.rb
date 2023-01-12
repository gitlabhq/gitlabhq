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

      RSPEC_TOP_LEVEL_DESCRIBE_REGEX = /^\+.?RSpec\.describe(.+)/.freeze
      FEATURE_CATEGORY_SUGGESTION = <<~SUGGESTION_MARKDOWN
      Consider adding `feature_category: <feature_category_name>` for this example if it is not set already.
      See [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#feature-category-metadata).
      SUGGESTION_MARKDOWN
      FEATURE_CATEGORY_KEYWORD = 'feature_category'

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
          MATCH_WITH_ARRAY_SUGGESTION,
          MATCH_WITH_ARRAY_REPLACEMENT
        )
      end

      def add_suggestions_for_project_factory_usage(filename)
        add_suggestion(
          filename,
          PROJECT_FACTORY_REGEX,
          PROJECT_FACTORY_SUGGESTION,
          PROJECT_FACTORY_REPLACEMENT
        )
      end

      def add_suggestions_for_feature_category(filename)
        file_lines = project_helper.file_lines(filename)
        changed_lines = helper.changed_lines(filename)

        changed_lines.each_with_index do |changed_line, i|
          next unless changed_line =~ RSPEC_TOP_LEVEL_DESCRIBE_REGEX

          next_line_in_file = file_lines[file_lines.find_index(changed_line.delete_prefix('+')) + 1]

          if changed_line.include?(FEATURE_CATEGORY_KEYWORD) || next_line_in_file.to_s.include?(FEATURE_CATEGORY_KEYWORD)
            next
          end

          line_number = file_lines.find_index(changed_line.delete_prefix('+'))
          next unless line_number

          suggested_line = file_lines[line_number]

          text = format(comment(FEATURE_CATEGORY_SUGGESTION), suggested_line: suggested_line)
          markdown(text, file: filename, line: line_number + 1)
        end
      end

      private

      def added_lines_matching(filename, regex)
        helper.changed_lines(filename).grep(/\A\+( )?/).grep(regex)
      end

      def add_suggestion(filename, regex, comment_text, replacement = nil, exclude = nil)
        added_lines = added_lines_matching(filename, regex)

        return if added_lines.empty?

        spec_file_lines = project_helper.file_lines(filename)

        added_lines.each_with_object([]) do |added_line, processed_line_numbers|
          line_number = find_line_number(spec_file_lines, added_line.delete_prefix('+'), exclude_indexes: processed_line_numbers)
          next unless line_number
          next if !exclude.nil? && added_line.include?(exclude)

          processed_line_numbers << line_number

          suggested_line = spec_file_lines[line_number]
          suggested_line = suggested_line.gsub(regex, replacement) unless replacement.nil?

          text = format(comment(comment_text), suggested_line: suggested_line)
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
