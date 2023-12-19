# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ProjectImportsCreatorsMetric, feature_category: :importers do
  let(:expected_value) { 3 }
  let(:expected_query) do
    "SELECT COUNT(DISTINCT \"projects\".\"creator_id\") FROM \"projects\" " \
      "WHERE \"projects\".\"import_type\" IS NOT NULL"
  end

  before_all do
    project = create :project, import_type: :jira, created_at: 3.days.ago
    create :project, import_type: :jira, created_at: 35.days.ago
    create :project, import_type: :jira, created_at: 3.days.ago
    create :project, created_at: 3.days.ago
    create :project, import_type: :jira, created_at: 3.days.ago, creator: project.creator
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d' } do
    let(:expected_value) { 2 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      "SELECT COUNT(DISTINCT \"projects\".\"creator_id\") FROM \"projects\" WHERE " \
        "\"projects\".\"import_type\" IS NOT NULL AND \"projects\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end
  end
end
