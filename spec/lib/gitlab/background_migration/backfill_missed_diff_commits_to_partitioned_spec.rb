# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMissedDiffCommitsToPartitioned,
  feature_category: :code_review_workflow do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_request_diffs) { table(:merge_request_diffs) }
  let(:commits_metadata) { table(:merge_request_commits_metadata) }

  # Post-swap on GitLab.com these are merge_request_diff_commits_archived and
  # merge_request_diff_commits
  let(:source_commits) { table(:merge_request_diff_commits) }
  let(:partitioned_commits) { table(:merge_request_diff_commits_b5377a7a34) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }

  let(:project) do
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:merge_request) do
    merge_requests.create!(
      target_project_id: project.id,
      target_branch: 'master',
      source_branch: 'feature',
      source_project_id: project.id
    )
  end

  let!(:merge_request_diff) do
    merge_request_diffs.create!(merge_request_id: merge_request.id, project_id: project.id)
  end

  let(:sub_batch_size) { 100 }

  let(:job_params) do
    {
      start_cursor: [0, 0],
      end_cursor: [merge_request_diff.id + 1_000, 999_999],
      batch_table: :merge_request_diff_commits,
      batch_column: :merge_request_diff_id,
      pause_ms: 0,
      sub_batch_size: sub_batch_size,
      job_arguments: %w[merge_request_diff_commits_b5377a7a34],
      connection: connection
    }
  end

  # The swap dropped these forward sync triggers on GitLab.com. In test schema they copy every insert
  # into the partitioned table, which makes the state this migration repairs impossible to build.
  around do |example|
    connection.execute(<<~SQL)
      ALTER TABLE merge_request_diff_commits DISABLE TRIGGER table_sync_trigger_57c8465cd7_insert;
      ALTER TABLE merge_request_diff_commits DISABLE TRIGGER table_sync_trigger_57c8465cd7_delete;
    SQL

    example.run
  ensure
    connection.execute(<<~SQL)
      ALTER TABLE merge_request_diff_commits ENABLE TRIGGER table_sync_trigger_57c8465cd7_insert;
      ALTER TABLE merge_request_diff_commits ENABLE TRIGGER table_sync_trigger_57c8465cd7_delete;
    SQL
  end

  def perform_migration
    described_class.new(**job_params).perform
  end

  # Composite primary key (id, project_id) means #id returns an array, so read the column.
  def create_metadata(sha:)
    commits_metadata.create!(
      project_id: project.id,
      sha: sha,
      commit_author_id: 1,
      committer_id: 1,
      authored_date: Time.current,
      committed_date: Time.current,
      message: "Message for #{sha}"
    )

    commits_metadata.where(project_id: project.id, sha: sha).pick(:id)
  end

  # project_id is nil because the archived column was never backfilled and only started being
  # written once the flag merge_request_diff_commits_partition was enabled.
  def create_deduplicated_commit(order:, metadata_id:, diff_id: merge_request_diff.id)
    source_commits.create!(
      merge_request_diff_id: diff_id,
      relative_order: order,
      merge_request_commits_metadata_id: metadata_id,
      project_id: nil,
      sha: nil,
      commit_author_id: nil,
      committer_id: nil
    )
  end

  describe '#perform' do
    context 'with a deduplicated row missing from the partitioned table' do
      let!(:metadata_id) { create_metadata(sha: 'aaa111') }

      before do
        create_deduplicated_commit(order: 0, metadata_id: metadata_id)
      end

      it 'starts from the broken state rather than a pre-synced one' do
        expect(partitioned_commits.count).to eq(0)
      end

      it 'copies the row, carrying the pointer, diff, project and ordering' do
        perform_migration

        expect(partitioned_commits.count).to eq(1)

        copied = partitioned_commits.first

        expect(copied.merge_request_commits_metadata_id).to eq(metadata_id)
        expect(copied.merge_request_diff_id).to eq(merge_request_diff.id)
        expect(copied.project_id).to eq(project.id)
        expect(copied.relative_order).to eq(0)
      end

      it 'leaves the legacy columns unset' do
        perform_migration

        copied = partitioned_commits.first

        expect(copied.sha).to be_nil
        expect(copied.commit_author_id).to be_nil
        expect(copied.committer_id).to be_nil
      end

      it 'inserts nothing on a second run' do
        perform_migration

        expect { perform_migration }.not_to change { partitioned_commits.count }
      end
    end

    context 'when a diff spans several sub batches' do
      let!(:metadata_id) { create_metadata(sha: 'bbb222') }
      let(:sub_batch_size) { 2 }

      before do
        5.times { |order| create_deduplicated_commit(order: order, metadata_id: metadata_id) }
      end

      it 'copies every row, so no commit is lost at a sub batch boundary' do
        perform_migration

        expect(partitioned_commits.order(:relative_order).pluck(:relative_order)).to eq([0, 1, 2, 3, 4])
      end
    end

    context 'when the row is already in the partitioned table' do
      let!(:metadata_id) { create_metadata(sha: 'ccc333') }

      before do
        create_deduplicated_commit(order: 0, metadata_id: metadata_id)

        partitioned_commits.create!(
          merge_request_commits_metadata_id: metadata_id,
          merge_request_diff_id: merge_request_diff.id,
          project_id: project.id,
          relative_order: 0
        )
      end

      it 'does not duplicate it' do
        expect { perform_migration }.not_to change { partitioned_commits.count }
      end
    end

    context 'when a source row has no metadata pointer' do
      before do
        source_commits.create!(
          merge_request_diff_id: merge_request_diff.id,
          relative_order: 0,
          merge_request_commits_metadata_id: nil,
          project_id: project.id,
          sha: 'eee555',
          commit_author_id: 1,
          committer_id: 1
        )
      end

      it 'skips it, because the partitioned table requires a pointer' do
        expect { perform_migration }.not_to change { partitioned_commits.count }
      end
    end

    context 'when the parent merge_request_diff is gone' do
      let!(:metadata_id) { create_metadata(sha: 'fff666') }

      before do
        create_deduplicated_commit(order: 0, metadata_id: metadata_id, diff_id: merge_request_diff.id + 500)
      end

      it 'skips the orphaned row' do
        expect { perform_migration }.not_to change { partitioned_commits.count }
      end
    end

    context 'when a row sits above the end cursor' do
      let!(:metadata_id) { create_metadata(sha: 'ggg777') }

      let!(:later_diff) do
        merge_request_diffs.create!(merge_request_id: merge_request.id, project_id: project.id)
      end

      before do
        create_deduplicated_commit(order: 0, metadata_id: metadata_id, diff_id: later_diff.id)

        job_params[:end_cursor] = [later_diff.id - 1, 999_999]
      end

      it 'is not copied' do
        expect { perform_migration }.not_to change { partitioned_commits.count }
      end
    end
  end
end
