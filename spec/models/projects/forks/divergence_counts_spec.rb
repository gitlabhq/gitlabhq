# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Forks::DivergenceCounts do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }

  describe '#counts' do
    let(:source_repo) { create(:project, :repository, :public).repository }
    let(:fork_repo) { fork_project(source_repo.project, user, { repository: true }).repository }
    let(:fork_branch) { 'fork-branch' }
    let(:cache_key) { ['project_forks', fork_repo.project.id, fork_branch, 'divergence_counts'] }

    def expect_cached_counts(value)
      counts = described_class.new(fork_repo.project, fork_branch).counts

      ahead, behind = value
      expect(counts).to eq({ ahead: ahead, behind: behind })

      cached_value = [source_repo.commit.sha, fork_repo.commit(fork_branch).sha, value]
      expect(Rails.cache.read(cache_key)).to eq(cached_value)
    end

    it 'shows how far behind/ahead a fork is from the upstream', :use_clean_rails_redis_caching do
      fork_repo.create_branch(fork_branch)

      expect_cached_counts([0, 0])

      fork_repo.commit_files(
        user,
        branch_name: fork_branch, message: 'Committing something',
        actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'New file' }]
      )

      expect_cached_counts([1, 0])

      source_repo.commit_files(
        user,
        branch_name: source_repo.root_ref, message: 'Commit to root ref',
        actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'One more' }]
      )

      source_repo.commit_files(
        user,
        branch_name: source_repo.root_ref, message: 'Another commit to root ref',
        actions: [{ action: :create, file_path: 'encoding/NEW-CHANGELOG', content: 'One more time' }]
      )

      expect_cached_counts([1, 2])
    end
  end
end
