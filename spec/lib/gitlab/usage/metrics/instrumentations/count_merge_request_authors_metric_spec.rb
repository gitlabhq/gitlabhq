# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountMergeRequestAuthorsMetric do
  let(:expected_value) { 1 }
  let(:start) { 30.days.ago.to_s(:db) }
  let(:finish) { 2.days.ago.to_s(:db) }

  let(:expected_query) do
    "SELECT COUNT(DISTINCT \"merge_requests\".\"author_id\") FROM \"merge_requests\"" \
    " WHERE \"merge_requests\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
  end

  before do
    user = create(:user)
    user2 = create(:user)

    create(:merge_request, created_at: 1.year.ago, author: user)
    create(:merge_request, created_at: 1.week.ago, author: user2)
    create(:merge_request, created_at: 1.week.ago, author: user2)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d' }
end
