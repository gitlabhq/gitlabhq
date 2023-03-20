# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module Specs
      include ::Tooling::Danger::Suggestor

      SPEC_FILES_REGEX = 'spec/'
      EE_PREFIX = 'ee/'

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
      PROJECT_FACTORY_SUGGESTION = <<~SUGGEST_COMMENT
      Project creations are very slow. Use `let_it_be`, `build` or `build_stubbed` if possible.
      See [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#optimize-factory-usage)
      for background information and alternative options.
      SUGGEST_COMMENT

      MATCH_WITH_ARRAY_REGEX = /(?<to>to\(?\s*)(?<matcher>match|eq)(?<expectation>[( ]?\[(?=.*,)[^\]]+)/.freeze
      MATCH_WITH_ARRAY_REPLACEMENT = '\k<to>match_array\k<expectation>'
      MATCH_WITH_ARRAY_SUGGESTION = <<~SUGGEST_COMMENT
      If order of the result is not important, please consider using `match_array` to avoid flakiness.
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
          filename: filename,
          regex: MATCH_WITH_ARRAY_REGEX,
          replacement: MATCH_WITH_ARRAY_REPLACEMENT,
          comment_text: MATCH_WITH_ARRAY_SUGGESTION
        )
      end

      def add_suggestions_for_project_factory_usage(filename)
        add_suggestion(
          filename: filename,
          regex: PROJECT_FACTORY_REGEX,
          replacement: PROJECT_FACTORY_REPLACEMENT,
          comment_text: PROJECT_FACTORY_SUGGESTION
        )
      end

      def add_suggestions_for_feature_category(filename)
        file_lines = project_helper.file_lines(filename)
        changed_lines = helper.changed_lines(filename)

        changed_lines.each_with_index do |changed_line, i|
          next unless changed_line =~ RSPEC_TOP_LEVEL_DESCRIBE_REGEX

          line_number = file_lines.find_index(changed_line.delete_prefix('+'))
          next unless line_number

          # Get the top level RSpec.describe line and the next 5 lines
          lines_to_check = file_lines[line_number, 5]
          # Remove all the lines after the first one that ends in `do`
          last_line_number_of_describe_declaration = lines_to_check.index { |line| line.end_with?(' do') }
          lines_to_check = lines_to_check[0..last_line_number_of_describe_declaration]

          next if lines_to_check.any? { |line| line.include?(FEATURE_CATEGORY_KEYWORD) }

          suggested_line = file_lines[line_number]

          markdown(comment(FEATURE_CATEGORY_SUGGESTION, suggested_line), file: filename, line: line_number.succ)
        end
      end
    end
  end
end
