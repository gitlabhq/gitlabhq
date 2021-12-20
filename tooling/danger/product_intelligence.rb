# frozen_string_literal: true
# rubocop:disable Style/SignalException

module Tooling
  module Danger
    module ProductIntelligence
      APPROVED_LABEL = 'product intelligence::approved'
      REVIEW_LABEL = 'product intelligence::review pending'

      WORKFLOW_LABELS = [
        APPROVED_LABEL,
        REVIEW_LABEL
      ].freeze

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

      private

      def has_workflow_labels?
        (WORKFLOW_LABELS & helper.mr_labels).any?
      end
    end
  end
end
