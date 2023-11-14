# frozen_string_literal: true

require_relative 'suggestion'

module Tooling
  module Danger
    class RubocopInlineDisableSuggestion < Suggestion
      MATCH = %r{^(?<line>.*#\s*rubocop\s*:\s*(?:disable|todo)\s+(?:[\w/]+(?:\s*,\s*[\w/]+)*))\s*(?!.*\s*--\s\S).*}
      REPLACEMENT = '\k<line> -- TODO: Reason why the rule must be disabled'

      SUGGESTION = <<~MESSAGE_MARKDOWN
        Consider removing this inline disabling and adhering to the rubocop rule.

        If that isn't possible, please provide the reason as a code comment in the
        same line where the rule is disabled separated by ` -- `.
        See [rubocop best practices](https://docs.gitlab.com/ee/development/rubocop_development_guide.html#disabling-rules-inline).

        ----

        [Improve this message](https://gitlab.com/gitlab-org/gitlab/-/blob/master/tooling/danger/rubocop_inline_disable_suggestion.rb)
        or [have feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/428157)?
      MESSAGE_MARKDOWN
    end
  end
end
