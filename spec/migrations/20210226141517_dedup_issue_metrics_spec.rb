# frozen_string_literal: true

require 'spec_helper'
require_migration!('dedup_issue_metrics')

RSpec.describe DedupIssueMetrics, :migration, schema: 20210205104425 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:metrics) { table(:issue_metrics) }
  let(:issue_params) { { title: 'title', project_id: project.id } }

  let!(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:issue_1) { issues.create!(issue_params) }
  let!(:issue_2) { issues.create!(issue_params) }
  let!(:issue_3) { issues.create!(issue_params) }

  let!(:duplicated_metrics_1) { metrics.create!(issue_id: issue_1.id, first_mentioned_in_commit_at: 1.day.ago, first_added_to_board_at: 5.days.ago, updated_at: 2.months.ago) }
  let!(:duplicated_metrics_2) { metrics.create!(issue_id: issue_1.id, first_mentioned_in_commit_at: Time.now, first_associated_with_milestone_at: Time.now, updated_at: 1.month.ago) }

  let!(:duplicated_metrics_3) { metrics.create!(issue_id: issue_3.id, first_mentioned_in_commit_at: 1.day.ago, updated_at: 2.months.ago) }
  let!(:duplicated_metrics_4) { metrics.create!(issue_id: issue_3.id, first_added_to_board_at: 1.day.ago, updated_at: 1.month.ago) }

  let!(:non_duplicated_metrics) { metrics.create!(issue_id: issue_2.id, first_added_to_board_at: 2.days.ago) }

  it 'deduplicates issue_metrics table' do
    expect { migrate! }.to change { metrics.count }.from(5).to(3)
  end

  it 'merges `duplicated_metrics_1` with `duplicated_metrics_2`' do
    migrate!

    expect(metrics.where(id: duplicated_metrics_1.id)).not_to exist

    merged_metrics = metrics.find_by(id: duplicated_metrics_2.id)

    expect(merged_metrics).to be_present
    expect(merged_metrics.first_mentioned_in_commit_at).to be_like_time(duplicated_metrics_2.first_mentioned_in_commit_at)
    expect(merged_metrics.first_added_to_board_at).to be_like_time(duplicated_metrics_1.first_added_to_board_at)
  end

  it 'merges `duplicated_metrics_3` with `duplicated_metrics_4`' do
    migrate!

    expect(metrics.where(id: duplicated_metrics_3.id)).not_to exist

    merged_metrics = metrics.find_by(id: duplicated_metrics_4.id)

    expect(merged_metrics).to be_present
    expect(merged_metrics.first_mentioned_in_commit_at).to be_like_time(duplicated_metrics_3.first_mentioned_in_commit_at)
    expect(merged_metrics.first_added_to_board_at).to be_like_time(duplicated_metrics_4.first_added_to_board_at)
  end

  it 'does not change non duplicated records' do
    expect { migrate! }.not_to change { non_duplicated_metrics.reload.attributes }
  end

  it 'does nothing when there are no metrics' do
    metrics.delete_all

    migrate!

    expect(metrics.count).to eq(0)
  end
end
