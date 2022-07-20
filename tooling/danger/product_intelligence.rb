# frozen_string_literal: true
# rubocop:disable Style/SignalException

module Tooling
  module Danger
    module ProductIntelligence
      APPROVED_LABEL = 'product intelligence::approved'
      REVIEW_LABEL = 'product intelligence::review pending'
      CHANGED_FILES_MESSAGE = <<~MSG
      For the following files, a review from the [Data team and Product Intelligence team](https://gitlab.com/groups/gitlab-org/analytics-section/product-intelligence/engineers/-/group_members?with_inherited_permissions=exclude) is recommended
      Please check the ~"product intelligence" [Service Ping guide](https://docs.gitlab.com/ee/development/service_ping/) or the [Snowplow guide](https://docs.gitlab.com/ee/development/snowplow/).

      For MR review guidelines, see the [Service Ping review guidelines](https://docs.gitlab.com/ee/development/service_ping/review_guidelines.html) or the [Snowplow review guidelines](https://docs.gitlab.com/ee/development/snowplow/review_guidelines.html).

      %<changed_files>s

      MSG

      WORKFLOW_LABELS = [
        APPROVED_LABEL,
        REVIEW_LABEL
      ].freeze

      def check!
        # exit if not matching files or if no product intelligence labels
        product_intelligence_paths_to_review = helper.changes_by_category[:product_intelligence]
        labels_to_add = missing_labels

        return if product_intelligence_paths_to_review.empty? || skip_review?

        warn format(CHANGED_FILES_MESSAGE, changed_files: helper.markdown_list(product_intelligence_paths_to_review)) unless has_approved_label?

        helper.labels_to_add.concat(labels_to_add) unless labels_to_add.empty?
      end

      private

      def missing_labels
        return [] unless helper.ci?

        labels = []
        labels << 'product intelligence' unless helper.mr_has_labels?('product intelligence')
        labels << REVIEW_LABEL unless has_workflow_labels?

        labels
      end

      def has_approved_label?
        helper.mr_labels.include?(APPROVED_LABEL)
      end

      def skip_review?
        helper.mr_has_labels?('growth experiment')
      end

      def has_workflow_labels?
        (WORKFLOW_LABELS & helper.mr_labels).any?
      end
    end
  end
end
