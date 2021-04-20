# frozen_string_literal: true

require 'spec_helper'

# If this spec fails, we need to add the new code review event to the correct aggregated metric
RSpec.describe 'Code review events' do
  it 'the aggregated metrics contain all the code review metrics' do
    path = Rails.root.join('config/metrics/aggregates/code_review.yml')
    aggregated_events = YAML.safe_load(File.read(path), aliases: true)&.map(&:with_indifferent_access)

    code_review_aggregated_events = aggregated_events
      .map { |event| event['events'] }
      .flatten
      .uniq

    code_review_events = Gitlab::UsageDataCounters::HLLRedisCounter.events_for_category("code_review")

    exceptions = %w[i_code_review_mr_diffs i_code_review_mr_single_file_diffs]
    code_review_aggregated_events += exceptions

    expect(code_review_events - code_review_aggregated_events).to be_empty
  end
end
