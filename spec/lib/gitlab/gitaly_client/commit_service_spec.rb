# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitalyClient::CommitService do
  let(:project) { create(:project, :repository) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:repository) { project.repository }
  let(:repository_message) { repository.gitaly_repository }
  let(:revision) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
  let(:commit) { project.commit(revision) }
  let(:client) { described_class.new(repository) }

  describe '#diff_from_parent' do
    context 'when a commit has a parent' do
      it 'sends an RPC request with the parent ID as left commit' do
        request = Gitaly::CommitDiffRequest.new(
          repository: repository_message,
          left_commit_id: 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660',
          right_commit_id: commit.id,
          collapse_diffs: false,
          enforce_limits: true,
          # Tests limitation parameters explicitly
          max_files: 100,
          max_lines: 5000,
          max_bytes: 512000,
          safe_max_files: 100,
          safe_max_lines: 5000,
          safe_max_bytes: 512000,
          max_patch_bytes: 102400
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

        client.diff_from_parent(commit)
      end
    end

    context 'when a commit does not have a parent' do
      it 'sends an RPC request with empty tree ref as left commit' do
        initial_commit = project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863').raw
        request        = Gitaly::CommitDiffRequest.new(
          repository: repository_message,
          left_commit_id: Gitlab::Git::EMPTY_TREE_ID,
          right_commit_id: initial_commit.id,
          collapse_diffs: false,
          enforce_limits: true,
          # Tests limitation parameters explicitly
          max_files: 100,
          max_lines: 5000,
          max_bytes: 512000,
          safe_max_files: 100,
          safe_max_lines: 5000,
          safe_max_bytes: 512000,
          max_patch_bytes: 102400
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

        client.diff_from_parent(initial_commit)
      end
    end

    it 'returns a Gitlab::GitalyClient::DiffStitcher' do
      ret = client.diff_from_parent(commit)

      expect(ret).to be_kind_of(Gitlab::GitalyClient::DiffStitcher)
    end

    it 'encodes paths correctly' do
      expect { client.diff_from_parent(commit, paths: ['encoding/test.txt', 'encoding/テスト.txt', nil]) }.not_to raise_error
    end
  end

  describe '#commit_deltas' do
    context 'when a commit has a parent' do
      it 'sends an RPC request with the parent ID as left commit' do
        request = Gitaly::CommitDeltaRequest.new(
          repository: repository_message,
          left_commit_id: 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660',
          right_commit_id: commit.id
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_delta).with(request, kind_of(Hash)).and_return([])

        client.commit_deltas(commit)
      end
    end

    context 'when a commit does not have a parent' do
      it 'sends an RPC request with empty tree ref as left commit' do
        initial_commit = project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863')
        request        = Gitaly::CommitDeltaRequest.new(
          repository: repository_message,
          left_commit_id: Gitlab::Git::EMPTY_TREE_ID,
          right_commit_id: initial_commit.id
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_delta).with(request, kind_of(Hash)).and_return([])

        client.commit_deltas(initial_commit)
      end
    end
  end

  describe '#between' do
    let(:from) { 'master' }
    let(:to) { Gitlab::Git::EMPTY_TREE_ID }

    it 'sends an RPC request' do
      request = Gitaly::CommitsBetweenRequest.new(
        repository: repository_message, from: from, to: to
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:commits_between)
        .with(request, kind_of(Hash)).and_return([])

      described_class.new(repository).between(from, to)
    end
  end

  describe '#diff_stats' do
    let(:left_commit_id) { 'master' }
    let(:right_commit_id) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }

    it 'sends an RPC request' do
      request = Gitaly::DiffStatsRequest.new(repository: repository_message,
                                             left_commit_id: left_commit_id,
                                             right_commit_id: right_commit_id)

      expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:diff_stats)
        .with(request, kind_of(Hash)).and_return([])

      described_class.new(repository).diff_stats(left_commit_id, right_commit_id)
    end
  end

  describe '#tree_entries' do
    let(:path) { '/' }

    it 'sends a get_tree_entries message' do
      expect_any_instance_of(Gitaly::CommitService::Stub)
        .to receive(:get_tree_entries)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.tree_entries(repository, revision, path, false)
    end

    context 'with UTF-8 params strings' do
      let(:revision) { "branch\u011F" }
      let(:path) { "foo/\u011F.txt" }

      it 'handles string encodings correctly' do
        expect_any_instance_of(Gitaly::CommitService::Stub)
          .to receive(:get_tree_entries)
          .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
          .and_return([])

        client.tree_entries(repository, revision, path, false)
      end
    end
  end

  describe '#commit_count' do
    before do
      expect_any_instance_of(Gitaly::CommitService::Stub)
        .to receive(:count_commits)
        .with(gitaly_request_with_path(storage_name, relative_path),
              kind_of(Hash))
        .and_return([])
    end

    it 'sends a commit_count message' do
      client.commit_count(revision)
    end

    context 'with UTF-8 params strings' do
      let(:revision) { "branch\u011F" }
      let(:path) { "foo/\u011F.txt" }

      it 'handles string encodings correctly' do
        client.commit_count(revision, path: path)
      end
    end
  end

  describe '#find_commit' do
    let(:revision) { Gitlab::Git::EMPTY_TREE_ID }

    it 'sends an RPC request' do
      request = Gitaly::FindCommitRequest.new(
        repository: repository_message, revision: revision
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit)
        .with(request, kind_of(Hash)).and_return(double(commit: nil))

      described_class.new(repository).find_commit(revision)
    end

    describe 'caching', :request_store do
      let(:commit_dbl) { double(id: 'f01b' * 10) }

      context 'when passed revision is a branch name' do
        it 'calls Gitaly' do
          expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit).twice.and_return(double(commit: commit_dbl))

          commit = nil
          2.times { commit = described_class.new(repository).find_commit('master') }

          expect(commit).to eq(commit_dbl)
        end
      end

      context 'when passed revision is a commit ID' do
        it 'returns a cached commit' do
          expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit).once.and_return(double(commit: commit_dbl))

          commit = nil
          2.times { commit = described_class.new(repository).find_commit('f01b' * 10) }

          expect(commit).to eq(commit_dbl)
        end
      end

      context 'when caching of the ref name is enabled' do
        it 'caches negative entries' do
          expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit).once.and_return(double(commit: nil))

          commit = nil
          2.times do
            ::Gitlab::GitalyClient.allow_ref_name_caching do
              commit = described_class.new(repository).find_commit('master')
            end
          end

          expect(commit).to eq(nil)
        end

        it 'returns a cached commit' do
          expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit).once.and_return(double(commit: commit_dbl))

          commit = nil
          2.times do
            ::Gitlab::GitalyClient.allow_ref_name_caching do
              commit = described_class.new(repository).find_commit('master')
            end
          end

          expect(commit).to eq(commit_dbl)
        end
      end
    end
  end

  describe '#commit_stats' do
    let(:request) do
      Gitaly::CommitStatsRequest.new(
        repository: repository_message, revision: revision
      )
    end
    let(:response) do
      Gitaly::CommitStatsResponse.new(
        oid: revision,
        additions: 11,
        deletions: 15
      )
    end

    subject { described_class.new(repository).commit_stats(revision) }

    it 'sends an RPC request' do
      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:commit_stats)
        .with(request, kind_of(Hash)).and_return(response)

      expect(subject.additions).to eq(11)
      expect(subject.deletions).to eq(15)
    end
  end
end
