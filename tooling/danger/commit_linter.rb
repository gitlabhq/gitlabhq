# frozen_string_literal: true

require_relative 'base_linter'
require_relative 'emoji_checker'

module Tooling
  module Danger
    class CommitLinter < BaseLinter
      MAX_CHANGED_FILES_IN_COMMIT = 3
      MAX_CHANGED_LINES_IN_COMMIT = 30
      SHORT_REFERENCE_REGEX = %r{([\w\-\/]+)?(?<!`)(#|!|&|%)\d+(?<!`)}.freeze

      def self.problems_mapping
        super.merge(
          {
            separator_missing: "The commit subject and body must be separated by a blank line",
            details_too_many_changes: "Commits that change #{MAX_CHANGED_LINES_IN_COMMIT} or more lines across " \
          "at least #{MAX_CHANGED_FILES_IN_COMMIT} files must describe these changes in the commit body",
            details_line_too_long: "The commit body should not contain more than #{MAX_LINE_LENGTH} characters per line",
            message_contains_text_emoji: "Avoid the use of Markdown Emoji such as `:+1:`. These add limited value " \
          "to the commit message, and are displayed as plain text outside of GitLab",
            message_contains_unicode_emoji: "Avoid the use of Unicode Emoji. These add no value to the commit " \
          "message, and may not be displayed properly everywhere",
            message_contains_short_reference: "Use full URLs instead of short references (`gitlab-org/gitlab#123` or " \
          "`!123`), as short references are displayed as plain text outside of GitLab"
          }
        )
      end

      def initialize(commit)
        super

        @linted = false
      end

      def fixup?
        commit.message.start_with?('fixup!', 'squash!')
      end

      def suggestion?
        commit.message.start_with?('Apply suggestion to')
      end

      def merge?
        commit.message.start_with?('Merge branch')
      end

      def revert?
        commit.message.start_with?('Revert "')
      end

      def multi_line?
        !details.nil? && !details.empty?
      end

      def lint
        return self if @linted

        @linted = true
        lint_subject
        lint_separator
        lint_details
        lint_message

        self
      end

      private

      def lint_separator
        return self unless separator && !separator.empty?

        add_problem(:separator_missing)

        self
      end

      def lint_details
        if !multi_line? && many_changes?
          add_problem(:details_too_many_changes)
        end

        details&.each_line do |line|
          line_without_urls = line.strip.gsub(%r{https?://\S+}, '')

          # If the line includes a URL, we'll allow it to exceed MAX_LINE_LENGTH characters, but
          # only if the line _without_ the URL does not exceed this limit.
          next unless line_too_long?(line_without_urls)

          add_problem(:details_line_too_long)
          break
        end

        self
      end

      def lint_message
        if message_contains_text_emoji?
          add_problem(:message_contains_text_emoji)
        end

        if message_contains_unicode_emoji?
          add_problem(:message_contains_unicode_emoji)
        end

        if message_contains_short_reference?
          add_problem(:message_contains_short_reference)
        end

        self
      end

      def files_changed
        commit.diff_parent.stats[:total][:files]
      end

      def lines_changed
        commit.diff_parent.stats[:total][:lines]
      end

      def many_changes?
        files_changed > MAX_CHANGED_FILES_IN_COMMIT && lines_changed > MAX_CHANGED_LINES_IN_COMMIT
      end

      def separator
        message_parts[1]
      end

      def details
        message_parts[2]&.gsub(/^Signed-off-by.*$/, '')
      end

      def message_contains_text_emoji?
        emoji_checker.includes_text_emoji?(commit.message)
      end

      def message_contains_unicode_emoji?
        emoji_checker.includes_unicode_emoji?(commit.message)
      end

      def message_contains_short_reference?
        commit.message.match?(SHORT_REFERENCE_REGEX)
      end

      def emoji_checker
        @emoji_checker ||= Tooling::Danger::EmojiChecker.new
      end
    end
  end
end
