# frozen_string_literal: true

require_relative 'suggestion'

module Tooling
  module Danger
    class PreventColumnAdditionSuggestion < Suggestion
      # Matches lines that disable column prevention without an approval issue URL
      # Requires the disable comment to include a link like:
      # https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/123456
      MATCH = %r{
        ^\+.*
        \#\s*rubocop\s*:\s*(?:disable|todo)\s+
        [\w/,\s]*
        Migration/PreventAddingColumns
        (?!.*https://gitlab\.com/gitlab-org/database-team/team-tasks/-/work_items/)
      }x

      REPLACEMENT = nil
      EXCEPTION_DOCS_URL = 'https://docs.gitlab.com/development/database/large_tables_limitations/#requesting-an-exception'
      SUGGESTION = <<~MESSAGE_MARKDOWN.freeze
        ⚠️ **`Migration/PreventAddingColumns` disabled without exception issue**

        This migration disables `Migration/PreventAddingColumns` which restricts adding columns
        to large or high-traffic tables.

        When bypassing this cop, you must:

        1. **Request an exception** by following the [documented process](#{EXCEPTION_DOCS_URL})
        2. **Add a link** to the approved exception issue in your disable comment

        Example:
        ```ruby
        # rubocop:disable Migration/PreventAddingColumns -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/123456
        ```

        ----

        [Improve this message](https://gitlab.com/gitlab-org/gitlab/-/blob/master/tooling/danger/prevent_column_addition_suggestion.rb)
        or [have feedback](https://gitlab.com/gitlab-org/gitlab/-/work_items/599128)?
      MESSAGE_MARKDOWN
    end
  end
end
