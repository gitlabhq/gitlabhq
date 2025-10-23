# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::Mirror::LocalRemoteBranchComparator, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository, :mirror) }

  let(:calculator) { described_class.new(project) }
  let(:local_branches) { [] }
  let(:remote_branches) { [] }

  describe '#calculate_changed_revisions' do
    subject(:changed_revisions) { calculator.calculate_changed_revisions }

    before do
      allow(project.repository).to receive(:branches).and_return(local_branches)
      allow(project.repository).to receive(:remote_branches)
        .with(::Repository::MIRROR_REMOTE)
        .and_return(remote_branches)
    end

    context 'when local repository is empty' do
      it 'returns ["--all"] for initial mirroring' do
        expect(changed_revisions).to eq(['--all'])
      end
    end

    context 'when no branches have changed' do
      let(:branch_sha) { '48f365f4fef7f4f2eabac6a57e655396f527a1e1' }
      let(:branch_commit) { RepoHelpers.sample_commit }
      let(:local_branches) { [Gitlab::Git::Branch.new(project.repository, 'main', branch_sha, branch_commit)] }
      let(:remote_branches) { [Gitlab::Git::Branch.new(project.repository, 'main', branch_sha, branch_commit)] }

      it 'returns nil' do
        expect(changed_revisions).to be_nil
      end
    end

    context 'when branches have changed' do
      let(:old_commit_sha) { '48f365f4fef7f4f2eabac6a57e655396f527a1e1' }
      let(:new_commit_sha) { '4c44e9f2a8b0f8c6cf90ec33034ce04c4a5a11c4' }
      let(:old_commit) { RepoHelpers.sample_commit }
      let(:new_commit) { RepoHelpers.another_sample_commit }

      context 'with a single updated branch' do
        let(:local_branches) { [Gitlab::Git::Branch.new(project.repository, 'main', old_commit_sha, old_commit)] }
        let(:remote_branches) { [Gitlab::Git::Branch.new(project.repository, 'main', new_commit_sha, new_commit)] }

        it 'returns SHA range for updated branch' do
          expect(changed_revisions).to eq(["#{old_commit_sha}..#{new_commit_sha}"])
        end
      end

      context 'with a new branch' do
        let(:local_branches) { [Gitlab::Git::Branch.new(project.repository, 'main', old_commit_sha, old_commit)] }
        let(:remote_branches) do
          [
            Gitlab::Git::Branch.new(project.repository, 'main', old_commit_sha, old_commit),
            Gitlab::Git::Branch.new(project.repository, 'feature', new_commit_sha, new_commit)
          ]
        end

        it 'returns full ref for new branch' do
          expect(changed_revisions).to eq(['refs/remotes/upstream/feature'])
        end
      end

      context 'with mixed updated and new branches' do
        let(:feature_commit_sha) { '0a358369b3d68f5d4e7cf2507d515364f8a1c4ec' }
        let(:feature_commit) { RepoHelpers.sample_big_commit }
        let(:local_branches) { [Gitlab::Git::Branch.new(project.repository, 'main', old_commit_sha, old_commit)] }
        let(:remote_branches) do
          [
            Gitlab::Git::Branch.new(project.repository, 'main', new_commit_sha, new_commit),
            Gitlab::Git::Branch.new(project.repository, 'feature', feature_commit_sha, feature_commit)
          ]
        end

        it 'returns SHA ranges for updated branches and full refs for new branches' do
          expect(changed_revisions).to contain_exactly(
            "#{old_commit_sha}..#{new_commit_sha}",
            'refs/remotes/upstream/feature'
          )
        end
      end

      context 'with unchanged branch mixed with changed branches' do
        let(:unchanged_sha) { 'abc123' }
        let(:local_branches) do
          [
            Gitlab::Git::Branch.new(project.repository, 'main', old_commit_sha, old_commit),
            Gitlab::Git::Branch.new(project.repository, 'stable', unchanged_sha, old_commit)
          ]
        end

        let(:remote_branches) do
          [
            Gitlab::Git::Branch.new(project.repository, 'main', new_commit_sha, new_commit),
            Gitlab::Git::Branch.new(project.repository, 'stable', unchanged_sha, old_commit)
          ]
        end

        it 'only includes changed branches' do
          expect(changed_revisions).to eq(["#{old_commit_sha}..#{new_commit_sha}"])
        end
      end
    end

    context 'with threshold limit' do
      let(:remote_branches) do
        # Create 3 remote branches (exceeds threshold of 2)
        Array.new(3) do |i|
          Gitlab::Git::Branch.new(
            project.repository,
            "branch-#{i}",
            '4c44e9f2a8b0f8c6cf90ec33034ce04c4a5a11c4',
            RepoHelpers.another_sample_commit
          )
        end
      end

      before do
        stub_const(
          'Gitlab::Repositories::Mirror::LocalRemoteBranchComparator::MAX_NUMBER_TO_PROCESS_SPECIFIC_REVISIONS', 2)
      end

      it 'returns ["--all"] when changes exceed threshold' do
        expect(changed_revisions).to eq(['--all'])
      end
    end

    context 'with branch_filter' do
      let(:branch_filter) { instance_double(Gitlab::Repositories::Mirror::BranchSkipFilter) }
      let(:calculator) { described_class.new(project, branch_filter: branch_filter) }
      let(:old_sha) { '48f365f4fef7f4f2eabac6a57e655396f527a1e1' }
      let(:new_sha) { '4c44e9f2a8b0f8c6cf90ec33034ce04c4a5a11c4' }
      let(:local_branches) { [Gitlab::Git::Branch.new(project.repository, 'main', old_sha, RepoHelpers.sample_commit)] }
      let(:remote_branches) do
        [
          Gitlab::Git::Branch.new(project.repository, 'main', new_sha, RepoHelpers.another_sample_commit),
          Gitlab::Git::Branch.new(project.repository, 'feature', 'abc123', RepoHelpers.sample_commit),
          Gitlab::Git::Branch.new(project.repository, 'protected', 'xyz789', RepoHelpers.sample_commit)
        ]
      end

      before do
        allow(branch_filter).to receive(:skip_branch?).with('main').and_return(false)
        allow(branch_filter).to receive(:skip_branch?).with('feature').and_return(false)
        allow(branch_filter).to receive(:skip_branch?).with('protected').and_return(true)
      end

      it 'excludes filtered branches from changed revisions' do
        expect(changed_revisions).to contain_exactly(
          "#{old_sha}..#{new_sha}",
          'refs/remotes/upstream/feature'
        )
      end
    end
  end
end
