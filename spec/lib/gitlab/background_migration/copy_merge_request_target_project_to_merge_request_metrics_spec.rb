# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CopyMergeRequestTargetProjectToMergeRequestMetrics, :migration, schema: 20200723125205 do
  let(:migration) { described_class.new }

  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:merge_requests) { table(:merge_requests) }
  let_it_be(:metrics) { table(:merge_request_metrics) }

  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let!(:project_1) { projects.create!(namespace_id: namespace.id) }
  let!(:project_2) { projects.create!(namespace_id: namespace.id) }
  let!(:merge_request_to_migrate_1) { merge_requests.create!(source_branch: 'a', target_branch: 'b', target_project_id: project_1.id) }
  let!(:merge_request_to_migrate_2) { merge_requests.create!(source_branch: 'c', target_branch: 'd', target_project_id: project_2.id) }
  let!(:merge_request_without_metrics) { merge_requests.create!(source_branch: 'e', target_branch: 'f', target_project_id: project_2.id) }

  let!(:metrics_1) { metrics.create!(merge_request_id: merge_request_to_migrate_1.id) }
  let!(:metrics_2) { metrics.create!(merge_request_id: merge_request_to_migrate_2.id) }

  let(:merge_request_ids) { [merge_request_to_migrate_1.id, merge_request_to_migrate_2.id, merge_request_without_metrics.id] }

  subject { migration.perform(merge_request_ids.min, merge_request_ids.max) }

  it 'copies `target_project_id` to the associated `merge_request_metrics` record' do
    subject

    expect(metrics_1.reload.target_project_id).to eq(project_1.id)
    expect(metrics_2.reload.target_project_id).to eq(project_2.id)
  end

  it 'does not create metrics record when it is missing' do
    subject

    expect(metrics.find_by_merge_request_id(merge_request_without_metrics.id)).to be_nil
  end
end
