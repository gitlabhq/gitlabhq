# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::JiraImportsFinishedMetric, feature_category: :importers do
  let(:expected_value) { 3 }
  let(:expected_query) do
    "SELECT COUNT(\"jira_imports\".\"id\") FROM \"jira_imports\" WHERE \"jira_imports\".\"status\" = 4"
  end

  before_all do
    # import with wrong state
    create :jira_import_state, created_at: 3.days.ago

    # imports to be counted in the metric
    create :jira_import_state, :finished, created_at: 3.days.ago
    create :jira_import_state, :finished, created_at: 35.days.ago
    create :jira_import_state, :finished, created_at: 3.days.ago
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }
end
