# frozen_string_literal: true

require_relative 'suggestion'

module Tooling
  module Danger
    class RubocopNewTodo < Suggestion
      # For example: `Gitlab/DocumentationLinks/HardcodedUrl:`.
      MATCH = %r{^\+\w+/.*:}
      REPLACEMENT = nil

      SUGGESTION = <<~MARKDOWN
        Please review RuboCop documentation related to [Enabling a new cop](https://docs.gitlab.com/ee/development/rubocop_development_guide.html#enabling-a-new-cop) and ensure you have followed all of the steps before resolving this comment.

        ----

        [Improve this message](https://gitlab.com/gitlab-org/gitlab/-/blob/master/tooling/danger/rubocop_new_todo.rb).
      MARKDOWN
    end
  end
end
