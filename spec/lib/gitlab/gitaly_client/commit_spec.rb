require 'spec_helper'

describe Gitlab::GitalyClient::Commit do
  describe '.diff_from_parent' do
    let(:diff_stub) { double('Gitaly::Diff::Stub') }
    let(:project) { create(:project, :repository) }
    let(:repository_message) { project.repository.gitaly_repository }
    let(:commit) { project.commit('913c66a37b4a45b9769037c55c2d238bd0942d2e') }

    context 'when a commit has a parent' do
      it 'sends an RPC request with the parent ID as left commit' do
        request = Gitaly::CommitDiffRequest.new(
          repository: repository_message,
          left_commit_id: 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660',
          right_commit_id: commit.id,
        )

        expect_any_instance_of(Gitaly::Diff::Stub).to receive(:commit_diff).with(request)

        described_class.diff_from_parent(commit)
      end
    end

    context 'when a commit does not have a parent' do
      it 'sends an RPC request with empty tree ref as left commit' do
        initial_commit = project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863')
        request        = Gitaly::CommitDiffRequest.new(
          repository: repository_message,
          left_commit_id: '4b825dc642cb6eb9a060e54bf8d69288fbee4904',
          right_commit_id: initial_commit.id,
        )

        expect_any_instance_of(Gitaly::Diff::Stub).to receive(:commit_diff).with(request)

        described_class.diff_from_parent(initial_commit)
      end
    end

    it 'returns a Gitlab::Git::DiffCollection' do
      ret = described_class.diff_from_parent(commit)

      expect(ret).to be_kind_of(Gitlab::Git::DiffCollection)
    end

    it 'passes options to Gitlab::Git::DiffCollection' do
      options = { max_files: 31, max_lines: 13 }

      expect(Gitlab::Git::DiffCollection).to receive(:new).with(kind_of(Enumerable), options)

      described_class.diff_from_parent(commit, options)
    end
  end
end
