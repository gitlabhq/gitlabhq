# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GroupImportsUsersMetric, feature_category: :importers do
  let(:expected_value) { 3 }
  let(:expected_query) { "SELECT COUNT(DISTINCT \"group_import_states\".\"user_id\") FROM \"group_import_states\"" }

  before_all do
    import = create :group_import_state, created_at: 3.days.ago
    create :group_import_state, created_at: 35.days.ago
    create :group_import_state, created_at: 3.days.ago
    create :group_import_state, created_at: 3.days.ago, user: import.user
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d' } do
    let(:expected_value) { 2 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      "SELECT COUNT(DISTINCT \"group_import_states\".\"user_id\") FROM \"group_import_states\" " \
        "WHERE \"group_import_states\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end
  end
end
