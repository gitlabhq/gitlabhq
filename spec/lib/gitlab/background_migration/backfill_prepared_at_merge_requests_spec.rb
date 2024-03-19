# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPreparedAtMergeRequests, :migration,
  feature_category: :code_review_workflow, schema: 20230616082958 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:mr_table) { table(:merge_requests) }

  let(:namespace) { namespaces.create!(name: 'batchtest1', type: 'Group', path: 'space1') }
  let(:proj_namespace) { namespaces.create!(name: 'proj1', path: 'proj1', type: 'Project', parent_id: namespace.id) }
  let(:project) do
    projects.create!(name: 'proj1', path: 'proj1', namespace_id: namespace.id, project_namespace_id: proj_namespace.id)
  end

  it 'updates merge requests with prepared_at nil' do
    time = Time.current

    mr_1 = mr_table.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature',
      prepared_at: nil, merge_status: 'checking')
    mr_2 = mr_table.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature',
      prepared_at: nil, merge_status: 'preparing')
    mr_3 = mr_table.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature',
      prepared_at: time)
    mr_4 = mr_table.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature',
      prepared_at: time, merge_status: 'checking')
    mr_5 = mr_table.create!(target_project_id: project.id, source_branch: 'master', target_branch: 'feature',
      prepared_at: time, merge_status: 'preparing')

    test_worker = described_class.new(
      start_id: mr_1.id,
      end_id: [(mr_5.id + 1), 100].max,
      batch_table: :merge_requests,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )

    expect(mr_1.prepared_at).to be_nil
    expect(mr_2.prepared_at).to be_nil
    expect(mr_3.prepared_at.to_i).to eq(time.to_i)
    expect(mr_4.prepared_at.to_i).to eq(time.to_i)
    expect(mr_5.prepared_at.to_i).to eq(time.to_i)

    test_worker.perform

    expect(mr_1.reload.prepared_at.to_i).to eq(mr_1.created_at.to_i)
    expect(mr_2.reload.prepared_at).to be_nil
    expect(mr_3.reload.prepared_at.to_i).to eq(time.to_i)
    expect(mr_4.reload.prepared_at.to_i).to eq(time.to_i)
    expect(mr_5.reload.prepared_at.to_i).to eq(time.to_i)
  end
end
