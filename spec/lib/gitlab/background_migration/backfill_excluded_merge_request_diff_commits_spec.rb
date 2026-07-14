# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillExcludedMergeRequestDiffCommits,
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

  let(:job_params) do
    {
      start_cursor: 1,
      end_cursor: 1000,
      batch_table: :excluded_merge_requests,
      batch_column: :id,
      pause_ms: 0,
      sub_batch_size: 1,
      job_arguments: [],
      connection: connection
    }
  end

  subject(:migration) { described_class.new(**job_params) }

  def run_migration
    migration.perform
  end

  def create_merge_request(source_branch:)
    merge_requests.create!(
      target_project_id: project.id,
      target_branch: 'master',
      source_branch: source_branch,
      source_project_id: project.id
    )
  end

  def create_diff(merge_request_id:)
    merge_request_diffs.create!(
      merge_request_id: merge_request_id,
      project_id: project.id
    )
  end

  def create_commit!(
    diff_id:,
    order:,
    sha:,
    author_id: 1,
    committer_id: 1
  )
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
      merge_request_commits_metadata_id: nil,
      project_id: nil
    )
  end

  def without_diff_commits_triggers
    connection.execute('ALTER TABLE merge_request_diff_commits DISABLE TRIGGER ALL;')
    yield
  ensure
    connection.execute('ALTER TABLE merge_request_diff_commits ENABLE TRIGGER ALL;')
  end

  def migrated_rows_for_diff(diff_id)
    merge_request_diff_commits_b5377a7a34.where(merge_request_diff_id: diff_id)
  end

  def metadata_for(sha)
    merge_request_commits_metadata.find_by(project_id: project.id, sha: sha)
  end

  context 'when excluded MR has commits' do
    let(:excluded_mr) { create_merge_request(source_branch: 'excluded') }
    let(:excluded_diff) { create_diff(merge_request_id: excluded_mr.id) }

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)

      without_diff_commits_triggers do
        create_commit!(diff_id: excluded_diff.id, order: 0, sha: 'abc123')
        create_commit!(diff_id: excluded_diff.id, order: 1, sha: 'def456')
      end
    end

    it 'creates commit metadata for missing metadata_ids' do
      expect { run_migration }
        .to change { merge_request_commits_metadata.where(project_id: project.id).count }
              .from(0).to(2)

      expect(merge_request_commits_metadata.where(project_id: project.id).pluck(:sha))
        .to match_array(%w[abc123 def456])
    end

    it 'migrates commits into the partitioned destination' do
      expect { run_migration }
        .to change { migrated_rows_for_diff(excluded_diff.id).count }
              .from(0).to(2)

      expect(
        migrated_rows_for_diff(excluded_diff.id).pluck(:relative_order).sort
      ).to match_array([0, 1])
    end

    it 'links migrated commits to the correct metadata' do
      run_migration

      meta = metadata_for('abc123')
      migrated = merge_request_diff_commits_b5377a7a34.find_by(
        merge_request_diff_id: excluded_diff.id,
        relative_order: 0,
        project_id: project.id
      )

      expect(migrated.merge_request_commits_metadata_id).to eq(meta[:id])
      expect(meta.commit_author_id).to eq(1)
      expect(meta.message).to eq('Commit message for abc123')
    end

    it 'is idempotent' do
      run_migration

      expect { run_migration }
        .to not_change { merge_request_commits_metadata.count }
              .and not_change { merge_request_diff_commits_b5377a7a34.count }
    end

    context 'when metadata was already written by a concurrent migration for a shared sha' do
      before do
        merge_request_commits_metadata.create!(
          project_id: project.id,
          sha: 'abc123',
          commit_author_id: 1,
          committer_id: 1,
          authored_date: Time.current,
          committed_date: Time.current,
          message: 'pre-existing from another MR'
        )
      end

      it 'still inserts the diff_commits row linked to the existing metadata' do
        run_migration

        meta = metadata_for('abc123')
        migrated = merge_request_diff_commits_b5377a7a34.find_by(
          merge_request_diff_id: excluded_diff.id,
          relative_order: 0,
          project_id: project.id
        )

        expect(migrated).not_to be_nil
        expect(migrated.merge_request_commits_metadata_id).to eq(meta[:id])
      end

      it 'does not create a duplicate metadata row' do
        expect { run_migration }
          .to not_change { merge_request_commits_metadata.where(project_id: project.id, sha: 'abc123').count }
      end
    end
  end

  context 'when excluded MR has no diffs' do
    let(:excluded_mr) { create_merge_request(source_branch: 'no_diffs') }

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)
    end

    it 'does not raise and writes nothing' do
      expect { run_migration }
        .to not_change { merge_request_diff_commits_b5377a7a34.count }
              .and not_change { merge_request_commits_metadata.count }
    end
  end

  context 'when excluded MR has more diffs than the limit' do
    let(:excluded_mr) { create_merge_request(source_branch: 'many_diffs') }

    let!(:diffs) do
      Array.new(5) { create_diff(merge_request_id: excluded_mr.id) }
    end

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)

      without_diff_commits_triggers do
        diffs.each_with_index do |diff, i|
          create_commit!(diff_id: diff.id, order: 0, sha: "sha_#{i}")
        end
      end

      stub_const("#{described_class}::MAX_DIFFS_PER_MR", 3)
    end

    it 'only migrates commits from the most recent diffs by id' do
      run_migration

      migrated_diff_ids =
        merge_request_diff_commits_b5377a7a34
          .where(merge_request_diff_id: diffs.map(&:id))
          .distinct
          .pluck(:merge_request_diff_id)
          .sort

      expect(migrated_diff_ids).to eq(diffs.last(3).map(&:id).sort)
    end
  end

  context 'when excluded MR has more commits than the limit' do
    let(:excluded_mr) { create_merge_request(source_branch: 'many_commits') }

    # Create diffs in order so IDs align with "oldest -> newest".
    let!(:diff_oldest) { create_diff(merge_request_id: excluded_mr.id) }
    let!(:diff_middle) { create_diff(merge_request_id: excluded_mr.id) }
    let!(:diff_newest) { create_diff(merge_request_id: excluded_mr.id) }

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)

      # 4 commits each (12 total). Limit to 6.
      without_diff_commits_triggers do
        4.times { |i| create_commit!(diff_id: diff_newest.id, order: i, sha: "newest_#{i}") }
        4.times { |i| create_commit!(diff_id: diff_middle.id, order: i, sha: "middle_#{i}") }
        4.times { |i| create_commit!(diff_id: diff_oldest.id, order: i, sha: "oldest_#{i}") }
      end

      stub_const("#{described_class}::MAX_COMMITS_PER_MR", 6)
    end

    it 'migrates at most MAX_COMMITS_PER_MR commits across all diffs' do
      run_migration

      total_migrated =
        merge_request_diff_commits_b5377a7a34
          .where(merge_request_diff_id: [diff_oldest.id, diff_middle.id, diff_newest.id])
          .count

      expect(total_migrated).to eq(6)
    end

    it 'migrates commits from newest diffs first' do
      run_migration

      expect(migrated_rows_for_diff(diff_newest.id).count).to eq(4)
      expect(migrated_rows_for_diff(diff_middle.id).count).to eq(2)
      expect(migrated_rows_for_diff(diff_oldest.id).count).to eq(0)
    end

    it 'retains the newest commits (highest relative_order) when the budget is exhausted mid-diff' do
      run_migration

      # diff_middle receives 2 of its 4 commits because the budget is consumed. Commits are
      # processed newest-first (descending relative_order), so the two highest orders survive.
      migrated_orders =
        migrated_rows_for_diff(diff_middle.id)
          .pluck(:relative_order)
          .sort

      expect(migrated_orders).to eq([2, 3])
    end
  end

  context 'when a single diff has more commits than COMMIT_BATCH_SIZE' do
    let(:excluded_mr) { create_merge_request(source_branch: 'big_diff') }
    let(:excluded_diff) { create_diff(merge_request_id: excluded_mr.id) }

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)

      without_diff_commits_triggers do
        7.times { |i| create_commit!(diff_id: excluded_diff.id, order: i, sha: "sha_#{i}") }
      end

      stub_const("#{described_class}::COMMIT_BATCH_SIZE", 3)
    end

    it 'migrates all commits across multiple batches' do
      run_migration

      expect(migrated_rows_for_diff(excluded_diff.id).count).to eq(7)
      expect(migrated_rows_for_diff(excluded_diff.id).pluck(:relative_order).sort).to eq((0..6).to_a)
    end
  end

  context 'when multiple diffs each need multiple commit batches' do
    let(:excluded_mr) { create_merge_request(source_branch: 'two_layer') }
    let!(:diff_a) { create_diff(merge_request_id: excluded_mr.id) }
    let!(:diff_b) { create_diff(merge_request_id: excluded_mr.id) }

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)

      without_diff_commits_triggers do
        5.times { |i| create_commit!(diff_id: diff_a.id, order: i, sha: "a_#{i}") }
        5.times { |i| create_commit!(diff_id: diff_b.id, order: i, sha: "b_#{i}") }
      end

      stub_const("#{described_class}::COMMIT_BATCH_SIZE", 2)
    end

    it 'migrates every commit across both layers of batching' do
      run_migration

      expect(migrated_rows_for_diff(diff_a.id).pluck(:relative_order).sort).to eq((0..4).to_a)
      expect(migrated_rows_for_diff(diff_b.id).pluck(:relative_order).sort).to eq((0..4).to_a)
    end

    it 'resets the relative_order cursor between diffs' do
      run_migration

      # Each diff has commits at relative_orders 0..4. If the cursor leaked across diffs,
      # the second diff would start mid-range and miss commits.
      expect(migrated_rows_for_diff(diff_a.id).count).to eq(5)
      expect(migrated_rows_for_diff(diff_b.id).count).to eq(5)
    end
  end

  context 'when a commit has a null commit_author_id or committer_id' do
    let(:excluded_mr) { create_merge_request(source_branch: 'null_author') }
    let(:excluded_diff) { create_diff(merge_request_id: excluded_mr.id) }

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)

      without_diff_commits_triggers do
        create_commit!(diff_id: excluded_diff.id, order: 0, sha: 'good_sha')
        create_commit!(diff_id: excluded_diff.id, order: 1, sha: 'null_author_sha', author_id: nil)
        create_commit!(diff_id: excluded_diff.id, order: 2, sha: 'null_committer_sha', committer_id: nil)
      end
    end

    it 'does not raise' do
      expect { run_migration }.not_to raise_error
    end

    it 'migrates commits with complete data and silently skips incomplete ones' do
      run_migration

      expect(merge_request_commits_metadata.where(project_id: project.id).pluck(:sha))
        .to match_array(%w[good_sha])

      expect(migrated_rows_for_diff(excluded_diff.id).pluck(:relative_order))
        .to match_array([0])
    end
  end

  context 'when MR is not in excluded_merge_requests' do
    let(:normal_mr) { create_merge_request(source_branch: 'normal') }
    let(:normal_diff) { create_diff(merge_request_id: normal_mr.id) }

    before do
      without_diff_commits_triggers do
        create_commit!(diff_id: normal_diff.id, order: 0, sha: 'normal_sha')
      end
    end

    it 'does not write anything' do
      expect { run_migration }
        .to not_change { merge_request_diff_commits_b5377a7a34.count }
              .and not_change { merge_request_commits_metadata.count }
    end
  end

  context 'when the same commit sha appears in multiple diffs of the excluded MR' do
    let(:excluded_mr) { create_merge_request(source_branch: 'shared') }
    let(:diff_1) { create_diff(merge_request_id: excluded_mr.id) }
    let(:diff_2) { create_diff(merge_request_id: excluded_mr.id) }

    before do
      excluded_merge_requests.create!(merge_request_id: excluded_mr.id)

      without_diff_commits_triggers do
        create_commit!(diff_id: diff_1.id, order: 0, sha: 'shared_sha')
        create_commit!(diff_id: diff_2.id, order: 0, sha: 'shared_sha')
      end
    end

    it 'creates only one metadata row per (project_id, sha)' do
      run_migration

      expect(merge_request_commits_metadata.where(project_id: project.id, sha: 'shared_sha').count).to eq(1)
    end

    it 'migrates both commits pointing to the same metadata row' do
      run_migration

      meta = metadata_for('shared_sha')
      migrated_1 = merge_request_diff_commits_b5377a7a34.find_by(merge_request_diff_id: diff_1.id, relative_order: 0)
      migrated_2 = merge_request_diff_commits_b5377a7a34.find_by(merge_request_diff_id: diff_2.id, relative_order: 0)

      expect(migrated_1.merge_request_commits_metadata_id).to eq(meta[:id])
      expect(migrated_2.merge_request_commits_metadata_id).to eq(meta[:id])
    end

    it 'is idempotent' do
      run_migration

      expect { run_migration }
        .to not_change { merge_request_commits_metadata.count }
              .and not_change { merge_request_diff_commits_b5377a7a34.count }
    end
  end

  context 'when multiple excluded MRs are within the cursor range' do
    let(:mr_a) { create_merge_request(source_branch: 'excluded_a') }
    let(:mr_b) { create_merge_request(source_branch: 'excluded_b') }

    let(:diff_a) { create_diff(merge_request_id: mr_a.id) }
    let(:diff_b) { create_diff(merge_request_id: mr_b.id) }

    before do
      excluded_merge_requests.create!(merge_request_id: mr_a.id)
      excluded_merge_requests.create!(merge_request_id: mr_b.id)

      without_diff_commits_triggers do
        create_commit!(diff_id: diff_a.id, order: 0, sha: 'a1')
        create_commit!(diff_id: diff_b.id, order: 0, sha: 'b1')
      end
    end

    it 'processes each excluded MR independently' do
      expect { run_migration }
        .to change { merge_request_diff_commits_b5377a7a34.count }
              .from(0).to(2)

      expect(merge_request_diff_commits_b5377a7a34.where(merge_request_diff_id: diff_a.id).count).to eq(1)
      expect(merge_request_diff_commits_b5377a7a34.where(merge_request_diff_id: diff_b.id).count).to eq(1)
    end
  end
end
