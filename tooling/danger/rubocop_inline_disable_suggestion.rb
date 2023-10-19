# frozen_string_literal: true

require_relative 'suggestion'

module Tooling
  module Danger
    class RubocopInlineDisableSuggestion < Suggestion
      MATCH = /^\+.*#\s*rubocop\s*:\s*(?:disable|todo)\s+/
      REPLACEMENT = nil

      SUGGESTION = <<~MESSAGE_MARKDOWN
        Consider removing this inline disabling and adhering to the rubocop rule.
        If that isn't possible, please provide context as a reply for reviewers.
        See [rubocop best practices](https://docs.gitlab.com/ee/development/rubocop_development_guide.html).

        ----

        [Improve this message](https://gitlab.com/gitlab-org/gitlab/-/blob/master/tooling/danger/rubocop_inline_disable_suggestion.rb)
        or [have feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/428157)?
      MESSAGE_MARKDOWN
    end
  end
end
