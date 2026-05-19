# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestDiffCommitsToPartitioned,
  feature_category: :code_review_workflow do
  let(:connection) { ApplicationRecord.connection }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_request_diffs) { table(:merge_request_diffs) }
  let(:merge_request_diff_commits) { table(:merge_request_diff_commits) }
  let(:merge_request_diff_commits_b5377a7a34) { table(:merge_request_diff_commits_b5377a7a34) }
  let(:merge_request_commits_metadata) { table(:merge_request_commits_metadata) }
  let(:excluded_merge_requests) { table(:excluded_merge_requests) }

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
    merge_request_diffs.create!(
      merge_request_id: merge_request.id,
      project_id: project.id
    )
  end

  let(:job_params) do
    {
      start_cursor: [0, 0],
      end_cursor: [merge_request_diff.id + 10, 10],
      batch_table: :merge_request_diff_commits,
      batch_column: :merge_request_diff_id,
      pause_ms: 0,
      sub_batch_size: 100,
      job_arguments: %w[merge_request_diff_commits_b5377a7a34],
      connection: connection
    }
  end

  def perform_migration
    described_class.new(**job_params).perform
  end

  def create_commit(diff_id:, order:, sha:, author_id: 1, committer_id: 1, metadata_id: nil, project_id: nil)
    merge_request_diff_commits.create!(
      merge_request_diff_id: diff_id,
      relative_order: order,
      sha: sha,
      commit_author_id: author_id,
      committer_id: committer_id,
      authored_date: Time.current,
      committed_date: Time.current,
      message: "Commit message for #{sha}",
      trailers: {},
      merge_request_commits_metadata_id: metadata_id,
      project_id: project_id
    )
  end

  context 'when backfilling commits without metadata' do
    let!(:commit_1) { create_commit(diff_id: merge_request_diff.id, order: 0, sha: 'abc123') }
    let!(:commit_2) { create_commit(diff_id: merge_request_diff.id, order: 1, sha: 'def456') }

    it 'creates metadata records for each commit' do
      expect { perform_migration }
        .to change { merge_request_commits_metadata.exists?(project_id: project.id, sha: 'abc123') }
              .from(false).to(true)
              .and change { merge_request_commits_metadata.exists?(project_id: project.id, sha: 'def456') }
                     .from(false).to(true)
    end

    it 'migrates commits to partitioned table' do
      expect { perform_migration }
        .to change {
          merge_request_diff_commits_b5377a7a34.exists?(
            merge_request_diff_id: merge_request_diff.id,
            relative_order: 0,
            project_id: project.id
          )
        }.from(false).to(true)
         .and change {
           merge_request_diff_commits_b5377a7a34.exists?(
             merge_request_diff_id: merge_request_diff.id,
             relative_order: 1,
             project_id: project.id
           )
         }.from(false).to(true)
    end

    it 'links migrated commits to correct metadata' do
      perform_migration

      metadata_1 = merge_request_commits_metadata.find_by(project_id: project.id, sha: 'abc123')
      migrated_commit_1 = merge_request_diff_commits_b5377a7a34.find_by(
        merge_request_diff_id: merge_request_diff.id,
        relative_order: 0,
        project_id: project.id
      )

      expect(migrated_commit_1.merge_request_commits_metadata_id).to eq(metadata_1[:id])
      expect(metadata_1.commit_author_id).to eq(1)
      expect(metadata_1.message).to eq('Commit message for abc123')
    end
  end

  context 'when commits already have metadata_id' do
    let!(:existing_metadata) do
      merge_request_commits_metadata.create!(
        project_id: project.id,
        sha: 'existing123',
        commit_author_id: 1,
        committer_id: 1,
        authored_date: Time.current,
        committed_date: Time.current,
        message: 'Existing commit'
      )
    end

    let!(:commit_with_metadata) do
      create_commit(
        diff_id: merge_request_diff.id,
        order: 0,
        sha: 'existing123',
        metadata_id: existing_metadata[:id]
      )
    end

    it 'does not create duplicate metadata' do
      expect { perform_migration }
        .not_to change { merge_request_commits_metadata.where(sha: 'existing123').count }
    end

    it 'migrates commit using existing metadata' do
      perform_migration

      migrated_commit = merge_request_diff_commits_b5377a7a34.find_by(
        merge_request_diff_id: merge_request_diff.id,
        relative_order: 0,
        project_id: project.id
      )

      expect(migrated_commit.merge_request_commits_metadata_id).to eq(existing_metadata[:id])
    end
  end

  context 'when the same commit appears in multiple diffs' do
    let!(:merge_request_diff_2) do
      merge_request_diffs.create!(
        merge_request_id: merge_request.id,
        project_id: project.id
      )
    end

    let!(:commit_diff_1) { create_commit(diff_id: merge_request_diff.id, order: 0, sha: 'shared_sha') }
    let!(:commit_diff_2) { create_commit(diff_id: merge_request_diff_2.id, order: 0, sha: 'shared_sha') }

    it 'creates only one metadata record for shared sha' do
      perform_migration

      expect(merge_request_commits_metadata.where(sha: 'shared_sha').count).to eq(1)
    end

    it 'migrates both commits pointing to the same metadata' do
      perform_migration

      metadata = merge_request_commits_metadata.find_by(project_id: project.id, sha: 'shared_sha')

      migrated_1 = merge_request_diff_commits_b5377a7a34.find_by(
        merge_request_diff_id: merge_request_diff.id,
        relative_order: 0
      )
      migrated_2 = merge_request_diff_commits_b5377a7a34.find_by(
        merge_request_diff_id: merge_request_diff_2.id,
        relative_order: 0
      )

      expect(migrated_1.merge_request_commits_metadata_id).to eq(metadata[:id])
      expect(migrated_2.merge_request_commits_metadata_id).to eq(metadata[:id])
    end
  end

  context 'when merge request is in excluded_merge_requests' do
    let!(:excluded_mr) do
      merge_requests.create!(
        target_project_id: project.id,
        target_branch: 'master',
        source_branch: 'excluded',
        source_project_id: project.id
      )
    end

    let!(:excluded_diff) do
      merge_request_diffs.create!(
        merge_request_id: excluded_mr.id,
        project_id: project.id
      )
    end

    let!(:excluded_commit) do
      create_commit(diff_id: excluded_diff.id, order: 0, sha: 'excluded_sha')
    end

    let!(:normal_commit) do
      create_commit(diff_id: merge_request_diff.id, order: 0, sha: 'normal_sha')
    end

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)
    end

    it 'does not migrate commits from excluded merge requests' do
      expect { perform_migration }
        .not_to change {
          merge_request_diff_commits_b5377a7a34.exists?(merge_request_diff_id: excluded_diff.id)
        }.from(false)
    end

    it 'does not create metadata for excluded commits' do
      expect { perform_migration }
        .not_to change {
          merge_request_commits_metadata.exists?(sha: 'excluded_sha')
        }.from(false)
    end

    it 'migrates normal commits' do
      expect { perform_migration }
        .to change {
          merge_request_diff_commits_b5377a7a34.exists?(merge_request_diff_id: merge_request_diff.id)
        }.from(false).to(true)
         .and change {
           merge_request_commits_metadata.exists?(sha: 'normal_sha')
         }.from(false).to(true)
    end
  end

  context 'when batch_table is a view' do
    let(:view_name) { 'merge_request_diff_commits_views_1' }
    let!(:commit) { create_commit(diff_id: merge_request_diff.id, order: 0, sha: 'view_sha') }

    # A diff and commit with an ID outside the cursor end bound - simulates a row that belongs
    # to a different parallel worker's range and must not be touched by this job.
    let!(:out_of_range_diff) do
      merge_request_diffs.create!(merge_request_id: merge_request.id, project_id: project.id)
    end

    let!(:out_of_range_commit) do
      create_commit(diff_id: out_of_range_diff.id, order: 0, sha: 'out_of_range_sha',
        project_id: project.id)
    end

    let(:job_params) do
      {
        start_cursor: [0, 0],
        end_cursor: [merge_request_diff.id, 10],
        batch_table: view_name,
        batch_column: :merge_request_diff_id,
        pause_ms: 0,
        sub_batch_size: 100,
        job_arguments: %w[merge_request_diff_commits_b5377a7a34],
        connection: connection
      }
    end

    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'migrates commits correctly when iterating via a view' do
      expect { perform_migration }
        .to change {
          merge_request_diff_commits_b5377a7a34.exists?(
            merge_request_diff_id: merge_request_diff.id,
            relative_order: 0,
            project_id: project.id
          )
        }.from(false).to(true)
    end

    it 'creates metadata records when iterating via a view' do
      expect { perform_migration }
        .to change { merge_request_commits_metadata.exists?(project_id: project.id, sha: 'view_sha') }
              .from(false).to(true)
    end

    it 'does not migrate commits outside the cursor bounds even though the view includes them' do
      perform_migration

      expect(merge_request_diff_commits_b5377a7a34.exists?(
        merge_request_diff_id: out_of_range_diff.id,
        relative_order: 0
      )).to be(false)
    end
  end

  context 'when migration is run multiple times' do
    let!(:commit) { create_commit(diff_id: merge_request_diff.id, order: 0, sha: 'idempotent') }

    it 'does not create duplicate metadata on second run' do
      perform_migration

      expect { perform_migration }
        .not_to change { merge_request_commits_metadata.where(sha: 'idempotent').count }.from(1)
    end

    it 'does not create duplicate commits on second run' do
      perform_migration

      expect { perform_migration }
        .not_to change {
          merge_request_diff_commits_b5377a7a34.where(
            merge_request_diff_id: merge_request_diff.id,
            relative_order: 0
          ).count
        }.from(1)
    end
  end

  context 'when the same SHA exists in two different projects' do
    let(:namespace_2) { namespaces.create!(name: 'namespace2', path: 'namespace2', organization_id: organization.id) }

    let(:project_2) do
      projects.create!(
        namespace_id: namespace_2.id,
        project_namespace_id: namespace_2.id,
        organization_id: organization.id
      )
    end

    let!(:merge_request_2) do
      merge_requests.create!(
        target_project_id: project_2.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project_2.id
      )
    end

    let!(:merge_request_diff_2) do
      merge_request_diffs.create!(
        merge_request_id: merge_request_2.id,
        project_id: project_2.id
      )
    end

    let!(:commit_project_1) do
      create_commit(
        diff_id: merge_request_diff.id,
        order: 0,
        sha: 'cross_project_sha'
      )
    end

    let!(:commit_project_2) do
      create_commit(
        diff_id: merge_request_diff_2.id,
        order: 0,
        sha: 'cross_project_sha'
      )
    end

    it 'creates separate metadata records per project' do
      perform_migration

      expect(merge_request_commits_metadata.where(sha: 'cross_project_sha').count).to eq(2)
      expect(merge_request_commits_metadata.exists?(project_id: project.id, sha: 'cross_project_sha')).to be(true)
      expect(merge_request_commits_metadata.exists?(project_id: project_2.id, sha: 'cross_project_sha')).to be(true)
    end

    it 'migrates each commit linked to its own project metadata' do
      perform_migration

      metadata_1 = merge_request_commits_metadata.find_by(project_id: project.id, sha: 'cross_project_sha')
      metadata_2 = merge_request_commits_metadata.find_by(project_id: project_2.id, sha: 'cross_project_sha')

      migrated_1 = merge_request_diff_commits_b5377a7a34.find_by(
        merge_request_diff_id: merge_request_diff.id,
        relative_order: 0
      )
      migrated_2 = merge_request_diff_commits_b5377a7a34.find_by(
        merge_request_diff_id: merge_request_diff_2.id,
        relative_order: 0
      )

      expect(migrated_1.merge_request_commits_metadata_id).to eq(metadata_1[:id])
      expect(migrated_2.merge_request_commits_metadata_id).to eq(metadata_2[:id])
    end
  end

  context 'when commits have NULL values in NOT NULL columns of the destination table' do
    let!(:valid_commit) { create_commit(diff_id: merge_request_diff.id, order: 0, sha: 'valid_sha') }

    let!(:null_author_commit) do
      merge_request_diff_commits.create!(
        merge_request_diff_id: merge_request_diff.id,
        relative_order: 1,
        sha: 'null_author_sha',
        commit_author_id: nil,
        committer_id: 1,
        authored_date: Time.current,
        committed_date: Time.current,
        message: 'Commit with null author',
        trailers: {},
        project_id: project.id
      )
    end

    let!(:null_committer_commit) do
      merge_request_diff_commits.create!(
        merge_request_diff_id: merge_request_diff.id,
        relative_order: 2,
        sha: 'null_committer_sha',
        commit_author_id: 1,
        committer_id: nil,
        authored_date: Time.current,
        committed_date: Time.current,
        message: 'Commit with null committer',
        trailers: {},
        project_id: project.id
      )
    end

    it 'does not raise and skips commits with null commit_author_id or committer_id' do
      expect { perform_migration }.not_to raise_error
    end

    it 'does not migrate commits with null commit_author_id' do
      perform_migration

      expect(merge_request_diff_commits_b5377a7a34.exists?(
        merge_request_diff_id: merge_request_diff.id,
        relative_order: 1
      )).to be(false)
    end

    it 'does not migrate commits with null committer_id' do
      perform_migration

      expect(merge_request_diff_commits_b5377a7a34.exists?(
        merge_request_diff_id: merge_request_diff.id,
        relative_order: 2
      )).to be(false)
    end

    it 'still migrates valid commits in the same batch' do
      expect { perform_migration }
        .to change {
          merge_request_diff_commits_b5377a7a34.exists?(
            merge_request_diff_id: merge_request_diff.id,
            relative_order: 0,
            project_id: project.id
          )
        }.from(false).to(true)
    end
  end
end
