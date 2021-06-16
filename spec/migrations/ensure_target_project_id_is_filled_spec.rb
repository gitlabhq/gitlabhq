# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureTargetProjectIdIsFilled, schema: 20200827085101 do
  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:merge_requests) { table(:merge_requests) }
  let_it_be(:metrics) { table(:merge_request_metrics) }

  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace') }
  let!(:project_1) { projects.create!(namespace_id: namespace.id) }
  let!(:project_2) { projects.create!(namespace_id: namespace.id) }
  let!(:merge_request_to_migrate_1) { merge_requests.create!(source_branch: 'a', target_branch: 'b', target_project_id: project_1.id) }
  let!(:merge_request_to_migrate_2) { merge_requests.create!(source_branch: 'c', target_branch: 'd', target_project_id: project_2.id) }
  let!(:merge_request_not_to_migrate) { merge_requests.create!(source_branch: 'e', target_branch: 'f', target_project_id: project_1.id) }

  let!(:metrics_1) { metrics.create!(merge_request_id: merge_request_to_migrate_1.id) }
  let!(:metrics_2) { metrics.create!(merge_request_id: merge_request_to_migrate_2.id) }
  let!(:metrics_3) { metrics.create!(merge_request_id: merge_request_not_to_migrate.id, target_project_id: project_1.id) }

  it 'migrates missing target_project_ids' do
    migrate!

    expect(metrics_1.reload.target_project_id).to eq(project_1.id)
    expect(metrics_2.reload.target_project_id).to eq(project_2.id)
    expect(metrics_3.reload.target_project_id).to eq(project_1.id)
  end
end
