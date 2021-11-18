# frozen_string_literal: true

require 'spec_helper'

# The underlying migration relies on the global models (e.g. Project). This
# means we also need to use FactoryBot factories to ensure everything is
# operating using the same types. If we use `table()` and similar methods we
# would have to duplicate a lot of logic just for these tests.
#
# rubocop: disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::FixMergeRequestDiffCommitUsers do
  let(:migration) { described_class.new }

  describe '#perform' do
    context 'when the project exists' do
      it 'processes the project' do
        project = create(:project)

        expect(migration).to receive(:process).with(project)
        expect(migration).to receive(:schedule_next_job)

        migration.perform(project.id)
      end

      it 'marks the background job as finished' do
        project = create(:project)

        Gitlab::Database::BackgroundMigrationJob.create!(
          class_name: 'FixMergeRequestDiffCommitUsers',
          arguments: [project.id]
        )

        migration.perform(project.id)

        job = Gitlab::Database::BackgroundMigrationJob
          .find_by(class_name: 'FixMergeRequestDiffCommitUsers')

        expect(job.status).to eq('succeeded')
      end
    end

    context 'when the project does not exist' do
      it 'does nothing' do
        expect(migration).not_to receive(:process)
        expect(migration).to receive(:schedule_next_job)

        migration.perform(-1)
      end
    end
  end

  describe '#process' do
    it 'processes the merge requests of the project' do
      project = create(:project, :repository)
      commit = project.commit
      mr = create(
        :merge_request_with_diffs,
        source_project: project,
        target_project: project
      )

      diff = mr.merge_request_diffs.first

      create(
        :merge_request_diff_commit,
        merge_request_diff: diff,
        sha: commit.sha,
        relative_order: 9000
      )

      migration.process(project)

      updated = diff
        .merge_request_diff_commits
        .find_by(sha: commit.sha, relative_order: 9000)

      expect(updated.commit_author_id).not_to be_nil
      expect(updated.committer_id).not_to be_nil
    end
  end

  describe '#update_commit' do
    let(:project) { create(:project, :repository) }
    let(:mr) do
      create(
        :merge_request_with_diffs,
        source_project: project,
        target_project: project
      )
    end

    let(:diff) { mr.merge_request_diffs.first }
    let(:commit) { project.commit }

    def update_row(migration, project, diff, row)
      migration.update_commit(project, row)

      diff
        .merge_request_diff_commits
        .find_by(sha: row.sha, relative_order: row.relative_order)
    end

    it 'populates missing commit authors' do
      commit_row = create(
        :merge_request_diff_commit,
        merge_request_diff: diff,
        sha: commit.sha,
        relative_order: 9000
      )

      updated = update_row(migration, project, diff, commit_row)

      expect(updated.commit_author.name).to eq(commit.to_hash[:author_name])
      expect(updated.commit_author.email).to eq(commit.to_hash[:author_email])
    end

    it 'populates missing committers' do
      commit_row = create(
        :merge_request_diff_commit,
        merge_request_diff: diff,
        sha: commit.sha,
        relative_order: 9000
      )

      updated = update_row(migration, project, diff, commit_row)

      expect(updated.committer.name).to eq(commit.to_hash[:committer_name])
      expect(updated.committer.email).to eq(commit.to_hash[:committer_email])
    end

    it 'leaves existing commit authors as-is' do
      user = create(:merge_request_diff_commit_user)
      commit_row = create(
        :merge_request_diff_commit,
        merge_request_diff: diff,
        sha: commit.sha,
        relative_order: 9000,
        commit_author: user
      )

      updated = update_row(migration, project, diff, commit_row)

      expect(updated.commit_author).to eq(user)
    end

    it 'leaves existing committers as-is' do
      user = create(:merge_request_diff_commit_user)
      commit_row = create(
        :merge_request_diff_commit,
        merge_request_diff: diff,
        sha: commit.sha,
        relative_order: 9000,
        committer: user
      )

      updated = update_row(migration, project, diff, commit_row)

      expect(updated.committer).to eq(user)
    end

    it 'does nothing when both the author and committer are present' do
      user = create(:merge_request_diff_commit_user)
      commit_row = create(
        :merge_request_diff_commit,
        merge_request_diff: diff,
        sha: commit.sha,
        relative_order: 9000,
        committer: user,
        commit_author: user
      )

      recorder = ActiveRecord::QueryRecorder.new do
        migration.update_commit(project, commit_row)
      end

      expect(recorder.count).to be_zero
    end

    it 'does nothing if the commit does not exist in Git' do
      user = create(:merge_request_diff_commit_user)
      commit_row = create(
        :merge_request_diff_commit,
        merge_request_diff: diff,
        sha: 'kittens',
        relative_order: 9000,
        committer: user,
        commit_author: user
      )

      recorder = ActiveRecord::QueryRecorder.new do
        migration.update_commit(project, commit_row)
      end

      expect(recorder.count).to be_zero
    end

    it 'does nothing when the committer/author are missing in the Git commit' do
      user = create(:merge_request_diff_commit_user)
      commit_row = create(
        :merge_request_diff_commit,
        merge_request_diff: diff,
        sha: commit.sha,
        relative_order: 9000,
        committer: user,
        commit_author: user
      )

      allow(migration).to receive(:find_or_create_user).and_return(nil)

      recorder = ActiveRecord::QueryRecorder.new do
        migration.update_commit(project, commit_row)
      end

      expect(recorder.count).to be_zero
    end
  end

  describe '#schedule_next_job' do
    it 'schedules the next background migration' do
      Gitlab::Database::BackgroundMigrationJob
        .create!(class_name: 'FixMergeRequestDiffCommitUsers', arguments: [42])

      expect(BackgroundMigrationWorker)
        .to receive(:perform_in)
        .with(2.minutes, 'FixMergeRequestDiffCommitUsers', [42])

      migration.schedule_next_job
    end

    it 'does nothing when there are no jobs' do
      expect(BackgroundMigrationWorker)
        .not_to receive(:perform_in)

      migration.schedule_next_job
    end
  end

  describe '#find_commit' do
    let(:project) { create(:project, :repository) }

    it 'finds a commit using Git' do
      commit = project.commit
      found = migration.find_commit(project, commit.sha)

      expect(found).to eq(commit.to_hash)
    end

    it 'caches the results' do
      commit = project.commit

      migration.find_commit(project, commit.sha)

      expect { migration.find_commit(project, commit.sha) }
        .not_to change { Gitlab::GitalyClient.get_request_count }
    end

    it 'returns an empty hash if the commit does not exist' do
      expect(migration.find_commit(project, 'kittens')).to eq({})
    end
  end

  describe '#find_or_create_user' do
    let(:project) { create(:project, :repository) }

    it 'creates missing users' do
      commit = project.commit.to_hash
      id = migration.find_or_create_user(commit, :author_name, :author_email)

      expect(MergeRequest::DiffCommitUser.count).to eq(1)

      created = MergeRequest::DiffCommitUser.first

      expect(created.name).to eq(commit[:author_name])
      expect(created.email).to eq(commit[:author_email])
      expect(created.id).to eq(id)
    end

    it 'returns users that already exist' do
      commit = project.commit.to_hash
      user1 = migration.find_or_create_user(commit, :author_name, :author_email)
      user2 = migration.find_or_create_user(commit, :author_name, :author_email)

      expect(user1).to eq(user2)
    end

    it 'caches the results' do
      commit = project.commit.to_hash

      migration.find_or_create_user(commit, :author_name, :author_email)

      recorder = ActiveRecord::QueryRecorder.new do
        migration.find_or_create_user(commit, :author_name, :author_email)
      end

      expect(recorder.count).to be_zero
    end

    it 'returns nil if the commit details are missing' do
      id = migration.find_or_create_user({}, :author_name, :author_email)

      expect(id).to be_nil
    end
  end

  describe '#matches_row' do
    it 'returns the query matches for the composite primary key' do
      row = double(:commit, merge_request_diff_id: 4, relative_order: 5)
      arel = migration.matches_row(row)

      expect(arel.to_sql).to eq(
        '("merge_request_diff_commits"."merge_request_diff_id", "merge_request_diff_commits"."relative_order") = (4, 5)'
      )
    end
  end
end
# rubocop: enable RSpec/FactoriesInMigrationSpecs
