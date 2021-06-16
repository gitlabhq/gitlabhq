# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersCreatingIssuesMetric do
  let_it_be(:author) { create(:user) }
  let_it_be(:issues) { create_list(:issue, 2, author: author, created_at: 4.days.ago) }
  let_it_be(:old_issue) { create(:issue, author: author, created_at: 2.months.ago) }

  context 'with all time frame' do
    let(:expected_value) { 1 }
    let(:expected_query) { 'SELECT COUNT(DISTINCT "issues"."author_id") FROM "issues"' }

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
  end

  context 'for 28d time frame' do
    let(:expected_value) { 1 }
    let(:start) { 30.days.ago.to_s(:db) }
    let(:finish) { 2.days.ago.to_s(:db) }
    let(:expected_query) { "SELECT COUNT(DISTINCT \"issues\".\"author_id\") FROM \"issues\" WHERE \"issues\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'" }

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d' }
  end
end
