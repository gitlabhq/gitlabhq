# frozen_string_literal: true

require_relative '../suggestion'

module Tooling
  module Danger
    module Specs
      class FeatureCategorySuggestion < Suggestion
        RSPEC_TOP_LEVEL_DESCRIBE_REGEX = /^\+.?RSpec\.describe(.+)/
        SUGGESTION = <<~SUGGESTION_MARKDOWN
          Consider adding `feature_category: <feature_category_name>` for this example if it is not set already.
          See [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#feature-category-metadata).
        SUGGESTION_MARKDOWN
        FEATURE_CATEGORY_KEYWORD = 'feature_category'

        def suggest
          file_lines = project_helper.file_lines(filename)
          changed_lines = helper.changed_lines(filename)

          changed_lines.each do |changed_line|
            next unless RSPEC_TOP_LEVEL_DESCRIBE_REGEX.match?(changed_line)

            line_number = file_lines.find_index(changed_line.delete_prefix('+'))
            next unless line_number

            # Get the top level RSpec.describe line and the next 5 lines
            lines_to_check = file_lines[line_number, 5]
            # Remove all the lines after the first one that ends in `do`
            last_line_number_of_describe_declaration = lines_to_check.index { |line| line.end_with?(' do') }
            lines_to_check = lines_to_check[0..last_line_number_of_describe_declaration]

            next if lines_to_check.any? { |line| line.include?(FEATURE_CATEGORY_KEYWORD) }

            suggested_line = file_lines[line_number]

            markdown(comment(SUGGESTION, suggested_line), file: filename, line: line_number.succ)
          end
        end
      end
    end
  end
end
