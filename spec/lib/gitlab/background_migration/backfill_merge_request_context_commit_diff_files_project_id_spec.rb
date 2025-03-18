# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMergeRequestContextCommitDiffFilesProjectId, feature_category: :code_review_workflow do
  let(:connection) { ApplicationRecord.connection }
  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:start_cursor) { [0, 0] }
  let(:end_cursor) { [merge_request_context_commits.maximum(:id), 1] }

  let(:migration) do
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :merge_request_context_commit_diff_files,
      batch_column: :merge_request_context_commit_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    )
  end

  shared_context 'for database tables' do
    let(:namespaces) { table(:namespaces) }
    let(:organizations) { table(:organizations) }
    let(:merge_request_context_commits) { table(:merge_request_context_commits) { |t| t.primary_key = :id } }
    let(:merge_requests) { table(:merge_requests) { |t| t.primary_key = :id } }
    let(:projects) { table(:projects) }
    let(:merge_request_context_commit_diff_files) do
      table(:merge_request_context_commit_diff_files) { |t| t.primary_key = :merge_request_context_commit_id }
    end
  end

  shared_context 'for namespaces' do
    let(:namespace1) { namespaces.create!(name: 'namespace 1', path: 'namespace1', organization_id: organization.id) }
    let(:namespace2) { namespaces.create!(name: 'namespace 2', path: 'namespace2', organization_id: organization.id) }
    let(:namespace3) { namespaces.create!(name: 'namespace 3', path: 'namespace3', organization_id: organization.id) }
    let(:namespace4) { namespaces.create!(name: 'namespace 4', path: 'namespace4', organization_id: organization.id) }
  end

  shared_context 'for projects' do
    let(:project1) do
      projects.create!(
        namespace_id: namespace1.id,
        project_namespace_id: namespace1.id,
        organization_id: organization.id
      )
    end

    let(:project2) do
      projects.create!(
        namespace_id: namespace2.id,
        project_namespace_id: namespace2.id,
        organization_id: organization.id
      )
    end

    let(:project3) do
      projects.create!(
        namespace_id: namespace3.id,
        project_namespace_id: namespace3.id,
        organization_id: organization.id
      )
    end

    let(:project4) do
      projects.create!(
        namespace_id: namespace4.id,
        project_namespace_id: namespace4.id,
        organization_id: organization.id
      )
    end

    let(:commit) { OpenSSL::Digest::SHA256.hexdigest(SecureRandom.hex) }
  end

  shared_context 'for merge requests' do
    let!(:merge_request_1) do
      merge_requests.create!(
        target_project_id: project1.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project1.id
      )
    end

    let!(:merge_request_2) do
      merge_requests.create!(
        target_project_id: project2.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project2.id
      )
    end

    let!(:merge_request_3) do
      merge_requests.create!(
        target_project_id: project3.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project3.id
      )
    end

    let!(:merge_request_4) do
      merge_requests.create!(
        target_project_id: project4.id,
        target_branch: 'master',
        source_branch: 'feature',
        source_project_id: project4.id
      )
    end
  end

  shared_context 'for merge requests context diff and commits' do
    let!(:merge_request_context_commit1) do
      merge_request_context_commits.create!(
        relative_order: 0,
        sha: commit,
        merge_request_id: merge_request_1.id,
        project_id: project1.id
      )
    end

    let!(:merge_request_context_commit2) do
      merge_request_context_commits.create!(
        relative_order: 0,
        sha: commit,
        merge_request_id: merge_request_2.id,
        project_id: project2.id
      )
    end

    let!(:merge_request_context_commit3) do
      merge_request_context_commits.create!(
        relative_order: 0,
        sha: commit,
        merge_request_id: merge_request_3.id,
        project_id: project3.id
      )
    end

    let!(:merge_request_context_commit4) do
      merge_request_context_commits.create!(
        relative_order: 0,
        sha: commit,
        merge_request_id: merge_request_4.id,
        project_id: project4.id
      )
    end

    let!(:merge_request_context_commit_diff_file_1) do
      merge_request_context_commit_diff_files.create!(merge_request_context_commit_id: merge_request_context_commit1.id,
        relative_order: 0, sha: commit, new_file: true, renamed_file: false, deleted_file: true,
        too_large: false, a_mode: 100500, b_mode: 100755, new_path: 'new_path', old_path: 'old_path', project_id: nil)
    end

    let!(:merge_request_context_commit_diff_file_2) do
      merge_request_context_commit_diff_files.create!(merge_request_context_commit_id: merge_request_context_commit2.id,
        relative_order: 0, sha: commit, new_file: true, renamed_file: false, deleted_file: true,
        too_large: false, a_mode: 100500, b_mode: 100755, new_path: 'new_path', old_path: 'old_path', project_id: nil)
    end

    let!(:merge_request_context_commit_diff_file_3) do
      merge_request_context_commit_diff_files.create!(merge_request_context_commit_id: merge_request_context_commit3.id,
        relative_order: 0, sha: commit, new_file: true, renamed_file: false, deleted_file: true,
        too_large: false, a_mode: 100500, b_mode: 100755, new_path: 'new_path', old_path: 'old_path', project_id: nil)
    end

    let!(:merge_request_context_commit_diff_file_4) do
      merge_request_context_commit_diff_files.create!(merge_request_context_commit_id: merge_request_context_commit4.id,
        relative_order: 0, sha: commit, new_file: true, renamed_file: false, deleted_file: true, too_large: false,
        a_mode: 100500, b_mode: 100755, new_path: 'new_path', old_path: 'old_path', project_id: project4.id)
    end
  end

  include_context 'for database tables'
  include_context 'for namespaces'
  include_context 'for projects'
  include_context 'for merge requests'
  include_context 'for merge requests context diff and commits'

  describe '#perform' do
    it 'backfills merge_request_context_commit_diff_files.project_id correctly for relevant records' do
      migration.perform

      expect(merge_request_context_commit_diff_file_1.reload.project_id).to eq(merge_request_context_commit1.project_id)
      expect(merge_request_context_commit_diff_file_2.reload.project_id).to eq(merge_request_context_commit2.project_id)
      expect(merge_request_context_commit_diff_file_3.reload.project_id).to eq(merge_request_context_commit3.project_id)
    end

    it 'does not update merge_request_context_commit_diff_files with pre-existing project_id' do
      expect { migration.perform }
        .not_to change { merge_request_context_commit_diff_file_4.reload.project_id }
    end
  end
end
