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
          collapse_diffs: true,
          enforce_limits: true,
          **Gitlab::Git::DiffCollection.collection_limits.to_h
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
          left_commit_id: '4b825dc642cb6eb9a060e54bf8d69288fbee4904',
          right_commit_id: initial_commit.id,
          collapse_diffs: true,
          enforce_limits: true,
          **Gitlab::Git::DiffCollection.collection_limits.to_h
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

        client.diff_from_parent(initial_commit)
      end
    end

    it 'returns a Gitlab::Git::DiffCollection' do
      ret = client.diff_from_parent(commit)

      expect(ret).to be_kind_of(Gitlab::Git::DiffCollection)
    end

    it 'passes options to Gitlab::Git::DiffCollection' do
      options = { max_files: 31, max_lines: 13, from_gitaly: true }

      expect(Gitlab::Git::DiffCollection).to receive(:new).with(kind_of(Enumerable), options)

      client.diff_from_parent(commit, options)
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
          left_commit_id: '4b825dc642cb6eb9a060e54bf8d69288fbee4904',
          right_commit_id: initial_commit.id
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_delta).with(request, kind_of(Hash)).and_return([])

        client.commit_deltas(initial_commit)
      end
    end
  end

  describe '#between' do
    let(:from) { 'master' }
    let(:to) { '4b825dc642cb6eb9a060e54bf8d69288fbee4904' }

    it 'sends an RPC request' do
      request = Gitaly::CommitsBetweenRequest.new(
        repository: repository_message, from: from, to: to
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:commits_between)
        .with(request, kind_of(Hash)).and_return([])

      described_class.new(repository).between(from, to)
    end
  end

  describe '#tree_entries' do
    let(:path) { '/' }

    it 'sends a get_tree_entries message' do
      expect_any_instance_of(Gitaly::CommitService::Stub)
        .to receive(:get_tree_entries)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.tree_entries(repository, revision, path)
    end

    context 'with UTF-8 params strings' do
      let(:revision) { "branch\u011F" }
      let(:path) { "foo/\u011F.txt" }

      it 'handles string encodings correctly' do
        expect_any_instance_of(Gitaly::CommitService::Stub)
          .to receive(:get_tree_entries)
          .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
          .and_return([])

        client.tree_entries(repository, revision, path)
      end
    end
  end
end
