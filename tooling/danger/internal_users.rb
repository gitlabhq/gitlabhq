# frozen_string_literal: true

require_relative 'suggestor'

module Tooling
  module Danger
    module InternalUsers
      include ::Tooling::Danger::Suggestor

      DOCS_PATH = 'doc/administration/internal_users.md'

      INLINE_COMMENT =
        <<~MESSAGE.freeze
        This line modifies internal user behavior or references an internal bot user.
        If this introduces new capabilities or changes existing behavior, please update the [internal users documentation](#{DOCS_PATH}).

        This comment will only appear once per file.
        MESSAGE

      MR_LEVEL_COMMENT =
        <<~SUGGEST_COMMENT.freeze
        This MR changes internal user behavior or usage.
        Please ensure [internal users documentation](#{DOCS_PATH}) is up to date.

        If this is not applicable, please ignore this message.

        Consider documenting:
        - Any changes to internal user behavior or capabilities
        - New use cases or integrations
        - Changes in how bots may interact with GitLab and its features
        SUGGEST_COMMENT

      BOT_METHODS = %w[
        support_bot
        alert_bot
        visual_review_bot
        ghost
        migration_bot
        security_bot
        automation_bot
        security_policy_bot
        admin_bot
        suggested_reviewers_bot
        llm_bot
        placeholder
        duo_code_review_bot
        import_user
      ].freeze

      BOT_NAMES = BOT_METHODS.join('|')

      BOT_METHOD_DEF_REGEX = /^\s*def\s+(?:self\.)?\s*(#{BOT_NAMES})(?!\w)/
      BOT_MODULE_CALL_REGEX = /^\s*Users::Internal\.(?:#{BOT_NAMES})(?!\w)/
      BOT_SYMBOL_TYPE_REGEX = /^\s*(?!#|")[^#"]*:(?:#{BOT_NAMES})(?!\w)/

      def add_comment_for_internal_users_changes
        return if helper.all_changed_files.include?(DOCS_PATH)

        violations_found = false

        helper.all_changed_files.each do |filename|
          next unless filename.end_with?('.rb')
          next unless file_has_violations?(filename)

          violations_found = true
          markdown(INLINE_COMMENT, file: filename)
        end

        warn(MR_LEVEL_COMMENT) if violations_found
      end

      private

      def file_has_violations?(filename)
        changed_lines = helper.changed_lines(filename)
        file_lines = project_helper.file_lines(filename)

        in_bot_method = false
        has_violation = false

        changed_lines.each do |line|
          clean_line = line.delete_prefix('+').delete_prefix('-').strip
          next unless clean_line.match?(BOT_METHOD_DEF_REGEX) ||
            clean_line.match?(BOT_MODULE_CALL_REGEX) ||
            clean_line.match?(BOT_SYMBOL_TYPE_REGEX)

          has_violation = true
          break
        end

        return has_violation if has_violation

        file_lines.each_with_index do |line, _|
          if line.match?(BOT_METHOD_DEF_REGEX)
            in_bot_method = true
          elsif line.strip == 'end'
            in_bot_method = false
          end

          next unless in_bot_method
          next unless changed_lines.any? { |cl| cl.delete_prefix('+').delete_prefix('-').strip == line.strip }

          has_violation = true
          break
        end

        has_violation
      end
    end
  end
end
