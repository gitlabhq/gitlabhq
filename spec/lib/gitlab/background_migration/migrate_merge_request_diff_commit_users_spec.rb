# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let(:merge_requests) { table(:merge_requests) }
  let(:diffs) { table(:merge_request_diffs) }
  let(:commits) do
    table(:merge_request_diff_commits).tap do |t|
      t.extend(SuppressCompositePrimaryKeyWarning)
    end
  end

  let(:commit_users) { described_class::MergeRequestDiffCommitUser }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:merge_request) do
    merge_requests.create!(
      source_branch: 'x',
      target_branch: 'master',
      target_project_id: project.id
    )
  end

  let(:diff) { diffs.create!(merge_request_id: merge_request.id) }
  let(:migration) { described_class.new }

  describe 'MergeRequestDiffCommit' do
    describe '.each_row_to_migrate' do
      it 'yields the rows to migrate for a given range' do
        commit1 = commits.create!(
          merge_request_diff_id: diff.id,
          relative_order: 0,
          sha: Gitlab::Database::ShaAttribute.serialize('123abc'),
          author_name: 'bob',
          author_email: 'bob@example.com',
          committer_name: 'bob',
          committer_email: 'bob@example.com'
        )

        commit2 = commits.create!(
          merge_request_diff_id: diff.id,
          relative_order: 1,
          sha: Gitlab::Database::ShaAttribute.serialize('123abc'),
          author_name: 'Alice',
          author_email: 'alice@example.com',
          committer_name: 'Alice',
          committer_email: 'alice@example.com'
        )

        # We stub this constant to make sure we run at least two pagination
        # queries for getting the data. This way we can test if the pagination
        # is actually working properly.
        stub_const(
          'Gitlab::BackgroundMigration::MigrateMergeRequestDiffCommitUsers::COMMIT_ROWS_PER_QUERY',
          1
        )

        rows = []

        described_class::MergeRequestDiffCommit.each_row_to_migrate(diff.id, diff.id + 1) do |row|
          rows << row
        end

        expect(rows.length).to eq(2)

        expect(rows[0].author_name).to eq(commit1.author_name)
        expect(rows[1].author_name).to eq(commit2.author_name)
      end
    end
  end

  describe 'MergeRequestDiffCommitUser' do
    describe '.union' do
      it 'produces a union of the given queries' do
        alice = commit_users.create!(name: 'Alice', email: 'alice@example.com')
        bob = commit_users.create!(name: 'Bob', email: 'bob@example.com')
        users = commit_users.union([
          commit_users.where(name: 'Alice').to_sql,
          commit_users.where(name: 'Bob').to_sql
        ])

        expect(users).to include(alice)
        expect(users).to include(bob)
      end
    end
  end

  describe '#perform' do
    it 'migrates the data in the range' do
      commits.create!(
        merge_request_diff_id: diff.id,
        relative_order: 0,
        sha: Gitlab::Database::ShaAttribute.serialize('123abc'),
        author_name: 'bob',
        author_email: 'bob@example.com',
        committer_name: 'bob',
        committer_email: 'bob@example.com'
      )

      migration.perform(diff.id, diff.id + 1)

      bob = commit_users.find_by(name: 'bob')
      commit = commits.first

      expect(commit.commit_author_id).to eq(bob.id)
      expect(commit.committer_id).to eq(bob.id)
    end

    it 'treats empty names and Emails the same as NULL values' do
      commits.create!(
        merge_request_diff_id: diff.id,
        relative_order: 0,
        sha: Gitlab::Database::ShaAttribute.serialize('123abc'),
        author_name: 'bob',
        author_email: 'bob@example.com',
        committer_name: '',
        committer_email: ''
      )

      migration.perform(diff.id, diff.id + 1)

      bob = commit_users.find_by(name: 'bob')
      commit = commits.first

      expect(commit.commit_author_id).to eq(bob.id)
      expect(commit.committer_id).to be_nil
    end

    it 'does not update rows without a committer and author' do
      commits.create!(
        merge_request_diff_id: diff.id,
        relative_order: 0,
        sha: Gitlab::Database::ShaAttribute.serialize('123abc')
      )

      migration.perform(diff.id, diff.id + 1)

      commit = commits.first

      expect(commit_users.count).to eq(0)
      expect(commit.commit_author_id).to be_nil
      expect(commit.committer_id).to be_nil
    end

    it 'marks the background job as done' do
      Gitlab::Database::BackgroundMigrationJob.create!(
        class_name: 'MigrateMergeRequestDiffCommitUsers',
        arguments: [diff.id, diff.id + 1]
      )

      migration.perform(diff.id, diff.id + 1)

      job = Gitlab::Database::BackgroundMigrationJob.first

      expect(job.status).to eq('succeeded')
    end
  end

  describe '#get_data_to_update' do
    it 'returns the users and commit rows to update' do
      commits.create!(
        merge_request_diff_id: diff.id,
        relative_order: 0,
        sha: Gitlab::Database::ShaAttribute.serialize('123abc'),
        author_name: 'bob' + ('a' * 510),
        author_email: 'bob@example.com',
        committer_name: 'bob' + ('a' * 510),
        committer_email: 'bob@example.com'
      )

      commits.create!(
        merge_request_diff_id: diff.id,
        relative_order: 1,
        sha: Gitlab::Database::ShaAttribute.serialize('456abc'),
        author_name: 'alice',
        author_email: 'alice@example.com',
        committer_name: 'alice',
        committer_email: 'alice@example.com'
      )

      users, to_update = migration.get_data_to_update(diff.id, diff.id + 1)

      bob_name = 'bob' + ('a' * 509)

      expect(users).to include(%w[alice alice@example.com])
      expect(users).to include([bob_name, 'bob@example.com'])

      expect(to_update[[diff.id, 0]])
        .to eq([[bob_name, 'bob@example.com'], [bob_name, 'bob@example.com']])

      expect(to_update[[diff.id, 1]])
        .to eq([%w[alice alice@example.com], %w[alice alice@example.com]])
    end

    it 'does not include a user if both the name and Email are missing' do
      commits.create!(
        merge_request_diff_id: diff.id,
        relative_order: 0,
        sha: Gitlab::Database::ShaAttribute.serialize('123abc'),
        author_name: nil,
        author_email: nil,
        committer_name: 'bob',
        committer_email: 'bob@example.com'
      )

      users, _ = migration.get_data_to_update(diff.id, diff.id + 1)

      expect(users).to eq([%w[bob bob@example.com]].to_set)
    end
  end

  describe '#get_user_rows_in_batches' do
    it 'retrieves all existing users' do
      alice = commit_users.create!(name: 'alice', email: 'alice@example.com')
      bob = commit_users.create!(name: 'bob', email: 'bob@example.com')

      users = [[alice.name, alice.email], [bob.name, bob.email]]
      mapping = {}

      migration.get_user_rows_in_batches(users, mapping)

      expect(mapping[%w[alice alice@example.com]]).to eq(alice)
      expect(mapping[%w[bob bob@example.com]]).to eq(bob)
    end
  end

  describe '#create_missing_users' do
    it 'creates merge request diff commit users that are missing' do
      alice = commit_users.create!(name: 'alice', email: 'alice@example.com')
      users = [%w[alice alice@example.com], %w[bob bob@example.com]]
      mapping = { %w[alice alice@example.com] => alice }

      migration.create_missing_users(users, mapping)

      expect(mapping[%w[alice alice@example.com]]).to eq(alice)
      expect(mapping[%w[bob bob@example.com]].name).to eq('bob')
      expect(mapping[%w[bob bob@example.com]].email).to eq('bob@example.com')
    end
  end

  describe '#update_commit_rows' do
    it 'updates the merge request diff commit rows' do
      to_update = { [42, 0] => [%w[alice alice@example.com], []] }
      user_mapping = { %w[alice alice@example.com] => double(:user, id: 1) }

      expect(migration)
        .to receive(:bulk_update_commit_rows)
        .with({ [42, 0] => [1, nil] })

      migration.update_commit_rows(to_update, user_mapping)
    end
  end

  describe '#bulk_update_commit_rows' do
    context 'when there are no authors and committers' do
      it 'does not update any rows' do
        migration.bulk_update_commit_rows({ [1, 0] => [] })

        expect(described_class::MergeRequestDiffCommit.connection)
          .not_to receive(:execute)
      end
    end

    context 'when there are only authors' do
      it 'only updates the author IDs' do
        author = commit_users.create!(name: 'Alice', email: 'alice@example.com')
        commit = commits.create!(
          merge_request_diff_id: diff.id,
          relative_order: 0,
          sha: Gitlab::Database::ShaAttribute.serialize('123abc')
        )

        mapping = {
          [commit.merge_request_diff_id, commit.relative_order] =>
            [author.id, nil]
        }

        migration.bulk_update_commit_rows(mapping)

        commit = commits.first

        expect(commit.commit_author_id).to eq(author.id)
        expect(commit.committer_id).to be_nil
      end
    end

    context 'when there are only committers' do
      it 'only updates the committer IDs' do
        committer =
          commit_users.create!(name: 'Alice', email: 'alice@example.com')

        commit = commits.create!(
          merge_request_diff_id: diff.id,
          relative_order: 0,
          sha: Gitlab::Database::ShaAttribute.serialize('123abc')
        )

        mapping = {
          [commit.merge_request_diff_id, commit.relative_order] =>
            [nil, committer.id]
        }

        migration.bulk_update_commit_rows(mapping)

        commit = commits.first

        expect(commit.committer_id).to eq(committer.id)
        expect(commit.commit_author_id).to be_nil
      end
    end

    context 'when there are both authors and committers' do
      it 'updates both the author and committer IDs' do
        author = commit_users.create!(name: 'Bob', email: 'bob@example.com')
        committer =
          commit_users.create!(name: 'Alice', email: 'alice@example.com')

        commit = commits.create!(
          merge_request_diff_id: diff.id,
          relative_order: 0,
          sha: Gitlab::Database::ShaAttribute.serialize('123abc')
        )

        mapping = {
          [commit.merge_request_diff_id, commit.relative_order] =>
            [author.id, committer.id]
        }

        migration.bulk_update_commit_rows(mapping)

        commit = commits.first

        expect(commit.commit_author_id).to eq(author.id)
        expect(commit.committer_id).to eq(committer.id)
      end
    end

    context 'when there are multiple commit rows to update' do
      it 'updates all the rows' do
        author = commit_users.create!(name: 'Bob', email: 'bob@example.com')
        committer =
          commit_users.create!(name: 'Alice', email: 'alice@example.com')

        commit1 = commits.create!(
          merge_request_diff_id: diff.id,
          relative_order: 0,
          sha: Gitlab::Database::ShaAttribute.serialize('123abc')
        )

        commit2 = commits.create!(
          merge_request_diff_id: diff.id,
          relative_order: 1,
          sha: Gitlab::Database::ShaAttribute.serialize('456abc')
        )

        mapping = {
          [commit1.merge_request_diff_id, commit1.relative_order] =>
            [author.id, committer.id],

          [commit2.merge_request_diff_id, commit2.relative_order] =>
            [author.id, nil]
        }

        migration.bulk_update_commit_rows(mapping)

        commit1 = commits.find_by(relative_order: 0)
        commit2 = commits.find_by(relative_order: 1)

        expect(commit1.commit_author_id).to eq(author.id)
        expect(commit1.committer_id).to eq(committer.id)

        expect(commit2.commit_author_id).to eq(author.id)
        expect(commit2.committer_id).to be_nil
      end
    end
  end

  describe '#primary_key' do
    it 'returns the primary key for the commits table' do
      key = migration.primary_key

      expect(key.to_sql).to eq('("merge_request_diff_commits"."merge_request_diff_id", "merge_request_diff_commits"."relative_order")')
    end
  end

  describe '#prepare' do
    it 'trims a value to at most 512 characters' do
      expect(migration.prepare('€' * 1_000)).to eq('€' * 512)
    end

    it 'returns nil if the value is an empty string' do
      expect(migration.prepare('')).to be_nil
    end
  end
end
