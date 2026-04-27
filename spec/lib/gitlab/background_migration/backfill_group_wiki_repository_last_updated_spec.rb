# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillGroupWikiRepositoryLastUpdated, feature_category: :geo_replication do
  let(:repo_with_commits) { instance_double(Gitlab::Git::Repository, commit: commit) }
  let(:repo_empty) { instance_double(Gitlab::Git::Repository, commit: nil) }
  let(:repo_missing) { instance_double(Gitlab::Git::Repository, commit: nil) }
  let(:repo_invalid) { instance_double(Gitlab::Git::Repository, commit: nil) }

  let(:shard) { table(:shards).create!(name: 'testshard') }

  let(:organization) { table(:organizations).create!(path: '/organization') }

  let(:group) { table(:namespaces) }
  let(:group_with_commits) do
    group.create!(
      name: 'group_with_commits', path: 'group_with_commits', type: 'Group', organization_id: organization.id
    )
  end

  let(:group_with_empty_repo) do
    group.create!(
      name: 'group_with_empty_repo', path: 'group_with_empty_repo', type: 'Group', organization_id: organization.id
    )
  end

  let(:group_with_no_repo) do
    group.create!(
      name: 'group_with_no_repo', path: 'group_with_no_repo', type: 'Group', organization_id: organization.id
    )
  end

  let(:group_with_invalid_storage) do
    group.create!(
      name: 'group_with_invalid_storage',
      path: 'group_with_invalid_storage',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let(:group_wiki_repository) { table(:group_wiki_repositories) }
  let(:record_with_commits) do
    group_wiki_repository.create!(shard_id: shard.id, group_id: group_with_commits.id, disk_path: '/one')
  end

  let(:record_with_empty_repo) do
    group_wiki_repository.create!(shard_id: shard.id, group_id: group_with_empty_repo.id, disk_path: '/two')
  end

  let(:record_with_no_repo) do
    group_wiki_repository.create!(shard_id: shard.id, group_id: group_with_no_repo.id, disk_path: '/three')
  end

  let(:record_with_invalid_storage) do
    group_wiki_repository.create!(shard_id: shard.id, group_id: group_with_invalid_storage.id, disk_path: '/invalid')
  end

  let(:commit) { instance_double(Gitlab::Git::Commit, committed_date: 3.days.ago) }
  let(:committed_date) { commit.committed_date }

  let(:migration) do
    described_class.new(
      start_cursor: [described_class::GroupWikiRepository.minimum(:group_id)],
      end_cursor: [described_class::GroupWikiRepository.maximum(:group_id)],
      batch_table: :group_wiki_repositories,
      batch_column: :group_id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  before do
    allow(Gitlab::Git::Repository).to receive(:new) do |_shard_name, path, *|
      case path
      when "#{record_with_commits.disk_path}.wiki.git" then repo_with_commits
      when "#{record_with_empty_repo.disk_path}.wiki.git" then repo_empty
      when "#{record_with_no_repo.disk_path}.wiki.git" then repo_missing
      when "#{record_with_invalid_storage.disk_path}.wiki.git" then repo_invalid
      end
    end

    sub_batch = described_class::GroupWikiRepository.where(
      group_id: [record_with_commits.group_id, record_with_empty_repo.group_id, record_with_no_repo.group_id,
        record_with_invalid_storage.group_id]
    )
    allow(migration).to receive(:each_sub_batch).and_yield(sub_batch)
  end

  describe '#perform' do
    subject(:perform_migration) { migration.perform }

    it 'updates last_repository_updated_at with the committed date for repos that have commits' do
      perform_migration

      expect(record_with_commits.reload.last_repository_updated_at)
        .to be_within(1.second).of(committed_date)
    end

    it 'does not update last_repository_updated_at when the repository has no commits' do
      expect { perform_migration }
        .not_to change { record_with_empty_repo.reload.last_repository_updated_at }
    end

    it 'does not update last_repository_updated_at when the repository does not exist' do
      expect { perform_migration }
        .not_to change { record_with_no_repo.reload.last_repository_updated_at }
    end

    it 'only updates records whose repositories exist and have commits', :aggregate_failures do
      perform_migration

      expect(record_with_commits.reload.last_repository_updated_at).not_to be_nil
      expect(record_with_empty_repo.reload.last_repository_updated_at).to be_nil
      expect(record_with_no_repo.reload.last_repository_updated_at).to be_nil
    end

    context 'when a record already has last_repository_updated_at set' do
      let(:old_date) { 2.weeks.ago }

      before do
        record_with_commits.update_column(:last_repository_updated_at, old_date)
      end

      it 'skips the record and does not overwrite the existing value' do
        expect { perform_migration }
          .not_to change { record_with_commits.reload.last_repository_updated_at }
      end
    end

    context 'when last_repository_updated_at is already nil for a record with no repo' do
      it 'leaves the column nil' do
        expect { perform_migration }
          .not_to change { record_with_no_repo.reload.last_repository_updated_at }
          .from(nil)
      end
    end

    context 'when the repository has an invalid shard_name' do
      before do
        allow(repo_invalid).to receive(:commit)
          .and_raise(RuntimeError, "storage not found")

        allow(Gitlab::Git::Repository).to receive(:new).with(
          anything, "#{record_with_invalid_storage.disk_path}.wiki.git", nil, nil
        ).and_return(repo_invalid)

        sub_batch = described_class::GroupWikiRepository.where(
          group_id: [record_with_commits.group_id, record_with_invalid_storage.group_id]
        )
        allow(migration).to receive(:each_sub_batch).and_yield(sub_batch)
      end

      it 'skips the record and leaves last_repository_updated_at nil' do
        expect { perform_migration }.not_to change {
          record_with_invalid_storage.reload.last_repository_updated_at
        }.from(nil)
      end

      it 'logs a warning with the relevant context' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          hash_including(
            message: "group: #{record_with_invalid_storage.group_id} -- storage not found",
            class: described_class.to_s
          )
        )
        perform_migration
      end

      it 'still updates other records in the same batch' do
        perform_migration

        expect(record_with_commits.reload.last_repository_updated_at)
          .to be_within(1.second).of(committed_date)
      end

      it 'raises the error if something else went wrong' do
        allow(Gitlab::Git::Repository).to receive(:new).with(anything, anything, nil, nil).and_raise("something else")
        expect { perform_migration }.to raise_error(RuntimeError, "something else")
      end
    end
  end
end
