# frozen_string_literal: true

module Tooling
  module Danger
    module CiTemplates
      CI_CD_TEMPLATE_MESSAGE = <<~MSG
        This merge request requires a CI/CD Template review. To make sure these
        changes are reviewed, take the following steps:

        1. Ensure the merge request has the ~"ci::templates" label.
        If the merge request modifies CI/CD Template files, Danger will do this for you.
        1. Prepare your MR for a CI/CD Template review according to the
        [template development guide](https://docs.gitlab.com/ee/development/cicd/templates.html).
        1. Assign and `@` mention the CI/CD Template reviewer suggested by Reviewer Roulette.
      MSG

      CI_CD_TEMPLATE_MODIFIED_WARNING = <<~MSG
        This merge request adds or changes templates, please consider updating the corresponding
        [Gitlab Component](https://gitlab.com/components).
      MSG

      def check!
        return unless helper.mr_labels.include?('ci::templates') || changes.any?

        message('This merge request adds or changes files that require a ' \
                'review from the CI/CD Templates maintainers.')

        markdown(CI_CD_TEMPLATE_MESSAGE)

        return unless changes.any?

        markdown(<<~MSG
              The following files require a review from the CI/CD Templates maintainers:
              #{helper.markdown_list(changes)}
        MSG
                )
        warn(CI_CD_TEMPLATE_MODIFIED_WARNING)
      end

      private

      def changes
        helper.changes.by_category(:ci_template).files
      end
    end
  end
end
