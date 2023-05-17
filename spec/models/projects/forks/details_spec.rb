# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Forks::Details, feature_category: :source_code_management do
  include ExclusiveLeaseHelpers
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:source_repo) { create(:project, :repository, :public).repository }
  let_it_be(:fork_repo) { fork_project(source_repo.project, user, { repository: true }).repository }

  let(:fork_branch) { 'fork-branch' }
  let(:cache_key) { ['project_fork_details', fork_repo.project.id, fork_branch].join(':') }

  describe '#counts', :use_clean_rails_redis_caching do
    def expect_cached_counts(value)
      counts = described_class.new(fork_repo.project, fork_branch).counts

      ahead, behind = value
      expect(counts).to eq({ ahead: ahead, behind: behind })

      cached_value = {
        source_sha: source_repo.commit.sha,
        sha: fork_repo.commit(fork_branch).sha,
        counts: value
      }
      expect(Rails.cache.read(cache_key)).to eq(cached_value)
    end

    it 'shows how far behind/ahead a fork is from the upstream' do
      fork_repo.create_branch(fork_branch)

      expect_cached_counts([0, 0])

      fork_repo.commit_files(
        user,
        branch_name: fork_branch, message: 'Committing something',
        actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'New file' }]
      )

      expect_cached_counts([1, 0])

      fork_repo.commit_files(
        user,
        branch_name: fork_branch, message: 'Committing something else',
        actions: [{ action: :create, file_path: 'encoding/ONE-MORE-CHANGELOG', content: 'One more new file' }]
      )

      expect_cached_counts([2, 0])

      source_repo.commit_files(
        user,
        branch_name: source_repo.root_ref, message: 'Commit to root ref',
        actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'One more' }]
      )

      expect_cached_counts([2, 1])

      source_repo.commit_files(
        user,
        branch_name: source_repo.root_ref, message: 'Another commit to root ref',
        actions: [{ action: :create, file_path: 'encoding/NEW-CHANGELOG', content: 'One more time' }]
      )

      expect_cached_counts([2, 2])

      # When the fork is too far ahead
      stub_const("#{described_class}::LATEST_COMMITS_COUNT", 1)
      fork_repo.commit_files(
        user,
        branch_name: fork_branch, message: 'Another commit to fork',
        actions: [{ action: :create, file_path: 'encoding/TOO-NEW-CHANGELOG', content: 'New file' }]
      )

      expect_cached_counts(nil)
    end

    context 'when counts calculated from a branch that exists upstream' do
      let_it_be(:source_repo) { create(:project, :repository, :public).repository }
      let_it_be(:fork_repo) { fork_project(source_repo.project, user, { repository: true }).repository }

      let(:fork_branch) { 'feature' }

      it 'compares the fork branch to upstream default branch' do
        # The branch itself diverges from the upstream default branch
        expect_cached_counts([1, 29])

        source_repo.commit_files(
          user,
          branch_name: source_repo.root_ref, message: 'Commit to root ref',
          actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'New file' }]
        )

        fork_repo.commit_files(
          user,
          branch_name: fork_branch, message: 'Committing to feature branch',
          actions: [{ action: :create, file_path: 'encoding/FEATURE-BRANCH', content: 'New file' }]
        )

        # It takes into account diverged commits from upstream AND from fork
        expect_cached_counts([2, 30])
      end
    end

    context 'when specified branch does not exist' do
      it 'returns nils as counts' do
        counts = described_class.new(fork_repo.project, 'non-existent-branch').counts
        expect(counts).to eq({ ahead: nil, behind: nil })
      end
    end
  end

  describe '#update!', :use_clean_rails_redis_caching do
    it 'updates the cache with the specified value' do
      value = { source_sha: source_repo.commit.sha, sha: fork_repo.commit.sha, counts: [0, 0], has_conflicts: true }

      described_class.new(fork_repo.project, fork_branch).update!(value)

      expect(Rails.cache.read(cache_key)).to eq(value)
    end
  end

  describe '#has_conflicts', :use_clean_rails_redis_caching do
    it 'returns whether merge for the stored commits failed due to conflicts' do
      details = described_class.new(fork_repo.project, fork_branch)

      expect do
        value = { source_sha: source_repo.commit.sha, sha: fork_repo.commit.sha, counts: [0, 0], has_conflicts: true }

        details.update!(value)
      end.to change { details.has_conflicts? }.from(false).to(true)
    end
  end

  describe '#exclusive_lease' do
    it 'returns exclusive lease to the details' do
      key = ['project_details', fork_repo.project.id, fork_branch].join(':')
      uuid = SecureRandom.uuid
      details = described_class.new(fork_repo.project, fork_branch)

      expect(Gitlab::ExclusiveLease).to receive(:get_uuid).with(key).and_return(uuid)
      expect(Gitlab::ExclusiveLease).to receive(:new).with(
        key, uuid: uuid, timeout: described_class::LEASE_TIMEOUT
      ).and_call_original

      expect(details.exclusive_lease).to be_a(Gitlab::ExclusiveLease)
    end
  end

  describe 'syncing?', :use_clean_rails_redis_caching do
    it 'returns whether there is a sync in progress' do
      details = described_class.new(fork_repo.project, fork_branch)

      expect(details.exclusive_lease.try_obtain).to be_present
      expect(details.syncing?).to eq(true)

      details.exclusive_lease.cancel
      expect(details.syncing?).to eq(false)
    end
  end
end
