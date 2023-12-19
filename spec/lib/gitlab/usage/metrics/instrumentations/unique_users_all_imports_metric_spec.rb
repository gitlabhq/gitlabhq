# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::UniqueUsersAllImportsMetric, feature_category: :importers do
  let(:expected_value) { 6 }
  let(:expected_query) do
    <<~SQL.squish
    SELECT
    (SELECT COUNT(DISTINCT "projects"."creator_id") FROM "projects" WHERE "projects"."import_type" IS NOT NULL) +
    (SELECT COUNT(DISTINCT "bulk_imports"."user_id") FROM "bulk_imports") +
    (SELECT COUNT(DISTINCT "jira_imports"."user_id") FROM "jira_imports") +
    (SELECT COUNT(DISTINCT "csv_issue_imports"."user_id") FROM "csv_issue_imports") +
    (SELECT COUNT(DISTINCT "group_import_states"."user_id") FROM "group_import_states")
    SQL
  end

  before_all do
    import = create :jira_import_state, created_at: 3.days.ago
    create :jira_import_state, created_at: 35.days.ago
    create :jira_import_state, created_at: 3.days.ago, user: import.user

    create :group_import_state, created_at: 3.days.ago
    create :issue_csv_import, created_at: 3.days.ago
    create :bulk_import, created_at: 3.days.ago
    create :project, import_type: :jira, created_at: 3.days.ago
  end

  before do
    described_class::IMPORTS_METRICS.each do |submetric_class|
      metric = submetric_class.new(time_frame: time_frame, options: options)
      allow(metric.send(:relation).connection).to receive(:transaction_open?).and_return(false)
    end
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all' }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d' } do
    let(:expected_value) { 5 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      <<~SQL.squish
      SELECT
      (SELECT COUNT(DISTINCT "projects"."creator_id") FROM "projects" WHERE "projects"."import_type" IS NOT NULL AND "projects"."created_at" BETWEEN '#{start}' AND '#{finish}') +
      (SELECT COUNT(DISTINCT "bulk_imports"."user_id") FROM "bulk_imports" WHERE "bulk_imports"."created_at" BETWEEN '#{start}' AND '#{finish}') +
      (SELECT COUNT(DISTINCT "jira_imports"."user_id") FROM "jira_imports" WHERE "jira_imports"."created_at" BETWEEN '#{start}' AND '#{finish}') +
      (SELECT COUNT(DISTINCT "csv_issue_imports"."user_id") FROM "csv_issue_imports" WHERE "csv_issue_imports"."created_at" BETWEEN '#{start}' AND '#{finish}') +
      (SELECT COUNT(DISTINCT "group_import_states"."user_id") FROM "group_import_states" WHERE "group_import_states"."created_at" BETWEEN '#{start}' AND '#{finish}')
      SQL
    end
  end
end
