# frozen_string_literal: true

require 'spec_helper'
require_migration!('dedup_mr_metrics')

RSpec.describe DedupMrMetrics, :migration, schema: 20200526013844 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:metrics) { table(:merge_request_metrics) }
  let(:merge_request_params) { { source_branch: 'x', target_branch: 'y', target_project_id: project.id } }

  let!(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:merge_request_1) { merge_requests.create!(merge_request_params) }
  let!(:merge_request_2) { merge_requests.create!(merge_request_params) }
  let!(:merge_request_3) { merge_requests.create!(merge_request_params) }

  let!(:duplicated_metrics_1) { metrics.create!(merge_request_id: merge_request_1.id, latest_build_started_at: 1.day.ago, first_deployed_to_production_at: 5.days.ago, updated_at: 2.months.ago) }
  let!(:duplicated_metrics_2) { metrics.create!(merge_request_id: merge_request_1.id, latest_build_started_at: Time.now, merged_at: Time.now, updated_at: 1.month.ago) }

  let!(:duplicated_metrics_3) { metrics.create!(merge_request_id: merge_request_3.id, diff_size: 30, commits_count: 20, updated_at: 2.months.ago) }
  let!(:duplicated_metrics_4) { metrics.create!(merge_request_id: merge_request_3.id, added_lines: 5, commits_count: nil, updated_at: 1.month.ago) }

  let!(:non_duplicated_metrics) { metrics.create!(merge_request_id: merge_request_2.id, latest_build_started_at: 2.days.ago) }

  it 'deduplicates merge_request_metrics table' do
    expect { migrate! }.to change { metrics.count }.from(5).to(3)
  end

  it 'merges `duplicated_metrics_1` with `duplicated_metrics_2`' do
    migrate!

    expect(metrics.where(id: duplicated_metrics_1.id)).not_to exist

    merged_metrics = metrics.find_by(id: duplicated_metrics_2.id)

    expect(merged_metrics).to be_present
    expect(merged_metrics.latest_build_started_at).to be_like_time(duplicated_metrics_2.latest_build_started_at)
    expect(merged_metrics.merged_at).to be_like_time(duplicated_metrics_2.merged_at)
    expect(merged_metrics.first_deployed_to_production_at).to be_like_time(duplicated_metrics_1.first_deployed_to_production_at)
  end

  it 'merges `duplicated_metrics_3` with `duplicated_metrics_4`' do
    migrate!

    expect(metrics.where(id: duplicated_metrics_3.id)).not_to exist

    merged_metrics = metrics.find_by(id: duplicated_metrics_4.id)

    expect(merged_metrics).to be_present
    expect(merged_metrics.diff_size).to eq(duplicated_metrics_3.diff_size)
    expect(merged_metrics.commits_count).to eq(duplicated_metrics_3.commits_count)
    expect(merged_metrics.added_lines).to eq(duplicated_metrics_4.added_lines)
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
