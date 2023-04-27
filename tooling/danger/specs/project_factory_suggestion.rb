# frozen_string_literal: true

require_relative '../suggestion'

module Tooling
  module Danger
    module Specs
      class ProjectFactorySuggestion < Suggestion
        PROJECT_FACTORIES = %w[
          :project
          :project_empty_repo
          :forked_project_with_submodules
          :project_with_design
        ].freeze

        MATCH = /
          ^\+?                                 # Start of the line, which may or may not have a `+`
          (?<head>\s*)                         # 0-many leading whitespace captured in a group named head
          let!?                                # Literal `let` which may or may not end in `!`
          (?<tail>                             # capture group named tail
            \([^)]+\)                          # Two parenthesis with any non-parenthesis characters between them
            \s*\{\s*                           # Opening curly brace surrounded by 0-many whitespace characters
            create\(                           # literal
            (?:#{PROJECT_FACTORIES.join('|')}) # Any of the project factory names
            \W                                 # Non-word character, avoid matching factories like :project_badge
          )                                    # end capture group named tail
        /x

        REPLACEMENT = '\k<head>let_it_be\k<tail>'
        SUGGESTION = <<~SUGGEST_COMMENT
          Project creations are very slow. Using `let_it_be`, `build` or `build_stubbed` can improve test performance.

          Warning: `let_it_be` may not be suitable if your test modifies data as this could result in state leaks!

          In those cases, please use `let_it_be_with_reload` or `let_it_be_with_refind` instead.

          If your are unsure which is the right method to use,
          please refer to [testing best practices](https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#optimize-factory-usage)
          for background information and alternative options for optimizing factory usage.

          Feel free to ignore this comment if you know `let` or `let!` are the better options and/or worry about causing state leaks.
        SUGGEST_COMMENT
      end
    end
  end
end
