# frozen_string_literal: true

require 'spec_helper'

# If this spec fails, we need to add the new code review event to the correct aggregated metric
# NOTE: ONLY user related metrics to be added to the aggregates - otherwise add it to the exception list
RSpec.describe 'Code review events' do
  it 'the aggregated metrics contain all the code review metrics' do
    mr_related_events = %w[i_code_review_create_mr i_code_review_mr_diffs i_code_review_mr_with_invalid_approvers i_code_review_mr_single_file_diffs i_code_review_total_suggestions_applied i_code_review_total_suggestions_added i_code_review_create_note_in_ipynb_diff i_code_review_create_note_in_ipynb_diff_mr i_code_review_create_note_in_ipynb_diff_commit i_code_review_merge_request_widget_license_compliance_warning]

    all_code_review_events = Gitlab::Usage::MetricDefinition.all.flat_map do |definition|
      next [] unless definition.attributes[:key_path].include?('.code_review.') &&
        definition.attributes[:status] == 'active' &&
        definition.attributes[:instrumentation_class] != 'AggregatedMetric'

      definition.attributes.dig(:options, :events)
    end.uniq.compact

    code_review_aggregated_events = Gitlab::Usage::MetricDefinition.all.flat_map do |definition|
      next [] unless code_review_aggregated_metric?(definition.attributes)

      definition.attributes.dig(:options, :events)
    end.uniq

    expect(all_code_review_events - (code_review_aggregated_events + mr_related_events)).to be_empty
  end

  def code_review_aggregated_metric?(attributes)
    return false unless attributes[:product_group] == 'code_review' && attributes[:status] == 'active'

    attributes[:instrumentation_class] == 'AggregatedMetric'
  end
end
