# frozen_string_literal: true

module Tooling
  module Danger
    module SecurityE2eTests
      QA_DIR_PATTERN = %r{\Aqa/}
      TEST_DIRS_PATTERN = %r{\A(qa|spec|ee/spec)/}

      SECURITY_E2E_TEST_WARNING = <<~MSG
        You've made changes to E2E tests in a security merge request. This is OK as long as you're making functional
        changes in line with the changes made to the tests. Please ensure you thoroughly review the intention and
        implementation of the tests you're modifying to avoid any unintentional regressions.
      MSG

      def check!
        return unless helper.security_mr?

        qa_changes = helper.all_changed_files.select { |file| file.match?(QA_DIR_PATTERN) }

        return if qa_changes.empty?

        non_test_changes = helper.all_changed_files.reject { |file| file.match?(TEST_DIRS_PATTERN) }

        return if non_test_changes.empty?

        warn SECURITY_E2E_TEST_WARNING, sticky: false
      end
    end
  end
end
