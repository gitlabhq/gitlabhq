# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixAwardEmojiNamespaceIdForIssues, feature_category: :team_planning do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:award_emoji) { table(:award_emoji) }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let(:source_namespace) do
    namespaces.create!(name: 'source', path: 'source', organization_id: organization.id)
  end

  let(:target_namespace) do
    namespaces.create!(name: 'target', path: 'target', organization_id: organization.id)
  end

  let(:target_project) do
    projects.create!(
      namespace_id: target_namespace.id,
      project_namespace_id: target_namespace.id,
      organization_id: organization.id
    )
  end

  let(:issue) do
    table(:issues).create!(
      title: 'Moved issue',
      iid: 1,
      namespace_id: target_namespace.id,
      project_id: target_project.id,
      work_item_type_id: 1 # Fixed ID of work_item_type `issue`
    )
  end

  let(:merge_request) do
    table(:merge_requests).create!(
      target_project_id: target_project.id,
      target_branch: 'main',
      source_branch: 'not-main'
    )
  end

  # namespace_id was copied from the source namespace when the issue was moved
  let!(:stale_issue_emoji) do
    award_emoji.create!(awardable_type: 'Issue', awardable_id: issue.id, namespace_id: source_namespace.id)
  end

  let!(:consistent_issue_emoji) do
    award_emoji.create!(awardable_type: 'Issue', awardable_id: issue.id, namespace_id: target_namespace.id)
  end

  let!(:orphaned_issue_emoji) do
    award_emoji.create!(
      awardable_type: 'Issue',
      awardable_id: non_existing_record_id,
      namespace_id: source_namespace.id
    )
  end

  let!(:merge_request_emoji) do
    award_emoji.create!(
      awardable_type: 'MergeRequest',
      awardable_id: merge_request.id,
      namespace_id: source_namespace.id
    )
  end

  let(:migration) do
    start_id, end_id = award_emoji.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :award_emoji,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    subject(:migrate) { migration.perform }

    it 'updates records in batches' do
      expect do
        migrate
        # 3 Issue related records, so 2 sub batches. The MergeRequest record is filtered out by scope_to
      end.to make_queries_matching(/UPDATE "award_emoji"/, 2)
    end

    it 'realigns namespace_id with the awarded issue', :aggregate_failures do
      expect do
        migrate
      end.to change { stale_issue_emoji.reload.namespace_id }.from(source_namespace.id).to(target_namespace.id).and(
        not_change { consistent_issue_emoji.reload.namespace_id }.from(target_namespace.id)
      )
    end

    it 'leaves records it cannot resolve or does not own untouched', :aggregate_failures do
      expect do
        migrate
      end.to not_change { orphaned_issue_emoji.reload.namespace_id }.from(source_namespace.id).and(
        not_change { merge_request_emoji.reload.namespace_id }.from(source_namespace.id)
      )
    end
  end
end
