# frozen_string_literal: true
# rubocop:disable Style/SignalException

module Tooling
  module Danger
    module ProductIntelligence
      WORKFLOW_LABELS = [
        'product intelligence::approved',
        'product intelligence::review pending'
      ].freeze

      def missing_labels
        return [] if !helper.ci? || helper.mr_has_labels?('growth experiment')

        labels = []
        labels << 'product intelligence' unless helper.mr_has_labels?('product intelligence')
        labels << 'product intelligence::review pending' unless has_workflow_labels?

        labels
      end

      private

      def has_workflow_labels?
        (WORKFLOW_LABELS & helper.mr_labels).any?
      end
    end
  end
end
