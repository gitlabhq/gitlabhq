# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillImportedDiffCommitsToPartitioned,
  feature_category: :code_review_workflow do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_request_diffs) { table(:merge_request_diffs) }
  let(:commit_users) { table(:merge_request_diff_commit_users) }
  let(:commits_metadata) { table(:merge_request_commits_metadata) }

  # Post-swap on GitLab.com these are merge_request_diff_commits_archived and merge_request_diff_commits
  let(:source_commits) { table(:merge_request_diff_commits) }
  let(:partitioned_commits) { table(:merge_request_diff_commits_b5377a7a34) }

  # The migration inserts the placeholder user into organization id=1 (the default org on GitLab.com).
  let!(:default_organization) do
    organizations.find_or_create_by!(id: 1) do |org|
      org.name = 'Default'
      org.path = 'default'
    end
  end

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }

  let(:project) { create_project(import_type: 'gitlab_project') }
  let(:merge_request) { create_merge_request(project) }
  let!(:merge_request_diff) { create_diff(merge_request) }

  let!(:real_user) { commit_users.create!(name: 'Real', email: 'real@example.com', organization_id: organization.id) }

  let(:min_project_id) { project.id }
  let(:max_project_id) { project.id + 100 }

  let(:job_params) do
    {
      start_cursor: [0],
      end_cursor: [merge_request_diff.id + 1_000],
      batch_table: :merge_request_diffs,
      batch_column: :id,
      pause_ms: 0,
      sub_batch_size: 100,
      job_arguments: [
        'merge_request_diff_commits', 'merge_request_diff_commits_b5377a7a34', min_project_id, max_project_id
      ],
      connection: connection
    }
  end

  # The swap dropped these forward sync triggers on GitLab.com. In test schema they copy inserts into the
  # partitioned table, which would hide rows this migration is meant to copy.
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

  def create_project(import_type:)
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id,
      import_type: import_type
    )
  end

  def create_merge_request(target_project)
    merge_requests.create!(
      target_project_id: target_project.id,
      source_project_id: target_project.id,
      target_branch: 'master',
      source_branch: 'feature'
    )
  end

  def create_diff(target_merge_request)
    merge_request_diffs.create!(
      merge_request_id: target_merge_request.id,
      project_id: target_merge_request.target_project_id
    )
  end

  def create_commit(
    order:, sha:, diff_id: merge_request_diff.id, author_id: nil, committer_id: nil, message: "Message for #{sha}")
    source_commits.create!(
      merge_request_diff_id: diff_id,
      relative_order: order,
      sha: sha,
      commit_author_id: author_id,
      committer_id: committer_id,
      authored_date: Time.current,
      committed_date: Time.current,
      message: message
    )
  end

  # Composite primary key (id, project_id) means #id returns an array, so read the column.
  def create_metadata(sha:, user_id: real_user.id)
    commits_metadata.create!(project_id: project.id, sha: sha, commit_author_id: user_id, committer_id: user_id)

    commits_metadata.where(project_id: project.id, sha: sha).pick(:id)
  end

  def copied_commit(order, diff_id: merge_request_diff.id)
    partitioned_commits.find_by(merge_request_diff_id: diff_id, relative_order: order)
  end

  def metadata_for(copied)
    commits_metadata.find_by(id: copied.merge_request_commits_metadata_id)
  end

  def placeholder
    commit_users.find_by(email: described_class::PLACEHOLDER_EMAIL, organization_id: 1)
  end

  describe '#perform', :aggregate_failures do
    context 'with a commit missing both users' do
      before do
        create_commit(order: 0, sha: 'aaa111')
      end

      it 'copies it once, with the placeholder as author and committer' do
        perform_migration

        metadata = metadata_for(copied_commit(0))

        expect(placeholder.name).to eq(described_class::PLACEHOLDER_NAME)
        expect(metadata.commit_author_id).to eq(placeholder.id)
        expect(metadata.committer_id).to eq(placeholder.id)
        expect(metadata.message).to eq('Message for aaa111')
        expect(copied_commit(0).project_id).to eq(project.id)

        expect { perform_migration }
          .to not_change { partitioned_commits.count }
          .and not_change { commits_metadata.count }
          .and not_change { commit_users.count }
      end
    end

    context 'with a commit missing only the committer' do
      let!(:second_diff) { create_diff(merge_request) }

      before do
        # The same commit with both users missing, in the lower diff ID, so the real author must win the tie-break.
        create_commit(order: 0, sha: 'bbb222')
        create_commit(order: 0, sha: 'bbb222', diff_id: second_diff.id, author_id: real_user.id)
      end

      it 'keeps the real author' do
        perform_migration

        metadata = metadata_for(copied_commit(0))

        expect(metadata.commit_author_id).to eq(real_user.id)
        expect(metadata.committer_id).to eq(placeholder.id)
      end
    end

    # The 2021 repair skipped every other batch of 100 rows, so copied rows can come before missing ones.
    context 'when more commits than the sub-batch size were already copied before a missing one' do
      let(:job_params) { super().merge(sub_batch_size: 2) }

      before do
        2.times do |order|
          create_commit(order: order, sha: "ggg00#{order}", author_id: real_user.id, committer_id: real_user.id)

          partitioned_commits.create!(
            merge_request_diff_id: merge_request_diff.id,
            relative_order: order,
            project_id: project.id,
            merge_request_commits_metadata_id: create_metadata(sha: "ggg00#{order}")
          )
        end

        create_commit(order: 2, sha: 'ggg002')
      end

      it 'copies only the missing one' do
        expect { perform_migration }.to change { partitioned_commits.count }.from(2).to(3)

        expect(metadata_for(copied_commit(2)).commit_author_id).to eq(placeholder.id)
      end
    end

    context 'when a sub-batch has more missing commits than the sub-batch size' do
      let(:job_params) { super().merge(sub_batch_size: 2) }
      let!(:second_diff) { create_diff(merge_request) }

      before do
        [merge_request_diff, second_diff].each do |diff|
          3.times { |order| create_commit(order: order, sha: "sha-#{diff.id}-#{order}", diff_id: diff.id) }
        end
      end

      it 'copies all of them' do
        expect { perform_migration }.to change { partitioned_commits.count }.from(0).to(6)
      end
    end

    context 'when the same commit is in two diffs and the real-user diff was already copied' do
      let!(:second_diff) { create_diff(merge_request) }
      let!(:existing_metadata_id) { create_metadata(sha: 'ddd444') }

      before do
        # NULL-user row in the source table -- this is what this migration copies.
        create_commit(order: 0, sha: 'ddd444')

        # Real-user row already copied to the partitioned table by the original backfill.
        partitioned_commits.create!(
          merge_request_diff_id: second_diff.id,
          relative_order: 0,
          project_id: project.id,
          merge_request_commits_metadata_id: existing_metadata_id
        )
      end

      it 'reuses the existing metadata record with real users' do
        expect { perform_migration }.not_to change { commits_metadata.count }

        expect(copied_commit(0).merge_request_commits_metadata_id).to eq(existing_metadata_id)
        expect(metadata_for(copied_commit(0)).commit_author_id).to eq(real_user.id)
      end
    end

    # Seen on GitLab.com: older MR versions of an import stored the message without its trailing newline.
    context 'when the same commit is missing in two diffs with different messages' do
      let!(:second_diff) { create_diff(merge_request) }

      before do
        create_commit(order: 0, sha: 'jjj000', message: 'Fix bug')
        create_commit(order: 0, sha: 'jjj000', diff_id: second_diff.id, message: "Fix bug\n")
      end

      it 'copies both rows with one metadata record that keeps the longer message' do
        expect { perform_migration }
          .to change { partitioned_commits.count }.by(2)
          .and change { commits_metadata.count }.by(1)

        expect(copied_commit(0).merge_request_commits_metadata_id)
          .to eq(copied_commit(0, diff_id: second_diff.id).merge_request_commits_metadata_id)
        expect(metadata_for(copied_commit(0)).message).to eq("Fix bug\n")
      end
    end

    context 'when the commit has no sha' do
      before do
        create_commit(order: 0, sha: nil)
      end

      it 'skips it' do
        expect { perform_migration }.not_to change { partitioned_commits.count }
      end
    end

    context 'when the project has an import type outside import/export' do
      let(:project) { create_project(import_type: 'github') }

      before do
        create_commit(order: 0, sha: 'eee555')
      end

      it 'skips it' do
        expect { perform_migration }.not_to change { partitioned_commits.count }
      end
    end

    context 'when the project was created outside the window' do
      let(:min_project_id) { project.id + 1 }

      before do
        create_commit(order: 0, sha: 'fff666')
      end

      it 'skips it' do
        expect { perform_migration }.not_to change { partitioned_commits.count }
      end
    end

    # Template imports go through import/export too, but the 2021 repair never targeted them.
    context 'when the project was imported from a custom project template' do
      let(:project) { create_project(import_type: 'gitlab_custom_project_template') }

      before do
        create_commit(order: 0, sha: 'hhh888')
      end

      it 'copies it' do
        expect { perform_migration }.to change { partitioned_commits.count }.by(1)
      end
    end
  end
end
