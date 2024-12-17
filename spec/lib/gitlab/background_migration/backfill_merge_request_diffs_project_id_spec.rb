# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestDiffsProjectId,
  feature_category: :code_review_workflow,
  schema: 20231114034017 do # schema before we introduced the invalid not-null constraint
  let!(:organization) { table(:organizations).create!(name: 'my organization', path: 'my-orgainzation') }
  let!(:tags_without_project_id) do
    13.times do
      namespace = table(:namespaces).create!(name: 'my namespace', path: 'my-namespace',
        organization_id: organization.id)
      project = table(:projects).create!(name: 'my project', path: 'my-project', namespace_id: namespace.id,
        project_namespace_id: namespace.id, organization_id: organization.id)
      merge_request = table(:merge_requests).create!(target_project_id: project.id, target_branch: 'main',
        source_branch: 'not-main')
      table(:merge_request_diffs).create!(merge_request_id: merge_request.id, project_id: nil)
    end
  end

  let!(:start_id) { table(:merge_request_diffs).minimum(:id) }
  let!(:end_id) { table(:merge_request_diffs).maximum(:id) }

  let!(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :merge_request_diffs,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 2,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'backfills the missing project_id for the batch' do
    backfilled_diffs = table(:merge_request_diffs)
      .joins('INNER JOIN merge_requests ON merge_request_diffs.merge_request_id = merge_requests.id')
      .where('merge_request_diffs.project_id = merge_requests.target_project_id')

    expect do
      migration.perform
    end.to change { backfilled_diffs.count }.from(0).to(13)
  end
end
