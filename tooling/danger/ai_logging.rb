# frozen_string_literal: true

module Tooling
  module Danger
    module AiLogging
      AI_LOGGING_WARNING = <<~MSG
        ## ⚠️ Potentially Non-Compliant AI Logging Detected

        This merge request contains AI logging that may not comply with GitLab's AI data usage policies.
        Please ensure proper warnings are included and review the [AI logging documentation](https://docs.gitlab.com/ee/development/ai_features/#logs).

        To resolve this:
        1. Ensure you're using `GitLab::Llm::Logger.build.info` or `GitLab::Llm::Logger.build.error` for AI-related logging.
        2. Add appropriate warnings to your AI logging calls.
        3. Ensure you're not logging sensitive or personal information.
        4. Consider if the logging should be gated behind the `expanded_ai_logging` feature flag.

        For more information, see: https://docs.gitlab.com/ee/user/gitlab_duo/data_usage.html
      MSG

      AI_LOGGING_FILES_MESSAGE = <<~MSG
        The following files contain potentially non-compliant AI logging:
      MSG

      def check_ai_logging
        return if helper.stable_branch?

        ai_logging_files = find_ai_logging_files

        return unless ai_logging_files.any?

        warn AI_LOGGING_WARNING
        markdown(AI_LOGGING_FILES_MESSAGE + helper.markdown_list(ai_logging_files))
      end

      private

      def find_ai_logging_files
        helper.git.modified_files.select do |file|
          next unless file.end_with?('.rb')

          content = helper.git.diff_for_file(file).patch

          next unless check_logger_or_path(content, file)

          !content.include?('expanded_ai_logging')
        end
      end

      def check_logger_or_path(file_content, file_path)
        logger_pattern = /@logger\s*=\s*Gitlab::Llm::Logger\.build/
        info_or_error_pattern = /logger\.((?:info(?!_or_debug)|error))(.*)$/

        (file_content.match?(logger_pattern) && file_content.match?(info_or_error_pattern)) ||
          (file_path.include?("llm") && file_content.match?(info_or_error_pattern))
      end
    end
  end
end
