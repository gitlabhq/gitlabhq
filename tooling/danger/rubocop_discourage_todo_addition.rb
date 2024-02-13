# frozen_string_literal: true

require_relative 'suggestion'
require_relative '../../rubocop/formatter/graceful_formatter'

module Tooling
  module Danger
    class RubocopDiscourageTodoAddition < Suggestion
      ONCE_PER_FILE = true
      MATCH = %r{\s*-\s*['"].*['"]\s*}
      REPLACEMENT = nil

      SUGGESTION = <<~MESSAGE_MARKDOWN
        Adding exclusions to RuboCop TODO files manually is discouraged.

        If it is not possible to resolve the exception, then
        [inline disabling](https://docs.gitlab.com/ee/development/rubocop_development_guide.html#disabling-rules-inline)
        should be used.

        ----

        To reduce noise, this message will only appear once per file.
      MESSAGE_MARKDOWN

      def suggest
        return if existing_grace_period? || added_grace_period?

        super
      end

      private

      def existing_grace_period?
        project_helper
          .file_lines(filename).grep(/\A\s*#{::RuboCop::Formatter::GracefulFormatter.grace_period_key_value}/).any?
      end

      def added_grace_period?
        helper.changed_lines(filename).grep(/\s*#{::RuboCop::Formatter::GracefulFormatter.grace_period_key_value}/).any?
      end
    end
  end
end
