# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::BulkImportsUsersMetric, feature_category: :importers do
  let(:expected_value) { 3 }
  let(:expected_query) { "SELECT COUNT(DISTINCT \"bulk_imports\".\"user_id\") FROM \"bulk_imports\"" }

  before_all do
    import = create :bulk_import, created_at: 3.days.ago
    create :bulk_import, created_at: 35.days.ago
    create :bulk_import, created_at: 3.days.ago
    create :bulk_import, created_at: 3.days.ago, user: import.user
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d' } do
    let(:expected_value) { 2 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      "SELECT COUNT(DISTINCT \"bulk_imports\".\"user_id\") FROM \"bulk_imports\" " \
        "WHERE \"bulk_imports\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end
  end
end
