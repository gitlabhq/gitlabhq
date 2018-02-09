require 'spec_helper'

describe Gitlab::GitalyClient::OperationService do
  let(:project) { create(:project) }
  let(:repository) { project.repository.raw }
  let(:client) { described_class.new(repository) }
  let(:user) { create(:user) }
  let(:gitaly_user) { Gitlab::Git::User.from_gitlab(user).to_gitaly }

  describe '#user_create_branch' do
    let(:branch_name) { 'new' }
    let(:start_point) { 'master' }
    let(:request) do
      Gitaly::UserCreateBranchRequest.new(
        repository: repository.gitaly_repository,
        branch_name: branch_name,
        start_point: start_point,
        user: gitaly_user
      )
    end
    let(:gitaly_commit) { build(:gitaly_commit) }
    let(:commit_id) { gitaly_commit.id }
    let(:gitaly_branch) do
      Gitaly::Branch.new(name: branch_name, target_commit: gitaly_commit)
    end
    let(:response) { Gitaly::UserCreateBranchResponse.new(branch: gitaly_branch) }
    let(:commit) { Gitlab::Git::Commit.new(repository, gitaly_commit) }

    subject { client.user_create_branch(branch_name, user, start_point) }

    it 'sends a user_create_branch message and returns a Gitlab::git::Branch' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_create_branch).with(request, kind_of(Hash))
        .and_return(response)

      expect(subject.name).to eq(branch_name)
      expect(subject.dereferenced_target).to eq(commit)
    end

    context "when pre_receive_error is present" do
      let(:response) do
        Gitaly::UserCreateBranchResponse.new(pre_receive_error: "something failed")
      end

      it "throws a PreReceive exception" do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_create_branch).with(request, kind_of(Hash))
          .and_return(response)

        expect { subject }.to raise_error(
          Gitlab::Git::HooksService::PreReceiveError, "something failed")
      end
    end
  end

  describe '#user_delete_branch' do
    let(:branch_name) { 'my-branch' }
    let(:request) do
      Gitaly::UserDeleteBranchRequest.new(
        repository: repository.gitaly_repository,
        branch_name: branch_name,
        user: gitaly_user
      )
    end
    let(:response) { Gitaly::UserDeleteBranchResponse.new }

    subject { client.user_delete_branch(branch_name, user) }

    it 'sends a user_delete_branch message' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_delete_branch).with(request, kind_of(Hash))
        .and_return(response)

      subject
    end

    context "when pre_receive_error is present" do
      let(:response) do
        Gitaly::UserDeleteBranchResponse.new(pre_receive_error: "something failed")
      end

      it "throws a PreReceive exception" do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_delete_branch).with(request, kind_of(Hash))
          .and_return(response)

        expect { subject }.to raise_error(
          Gitlab::Git::HooksService::PreReceiveError, "something failed")
      end
    end
  end

  describe '#user_ff_branch' do
    let(:target_branch) { 'my-branch' }
    let(:source_sha) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }
    let(:request) do
      Gitaly::UserFFBranchRequest.new(
        repository: repository.gitaly_repository,
        branch: target_branch,
        commit_id: source_sha,
        user: gitaly_user
      )
    end
    let(:branch_update) do
      Gitaly::OperationBranchUpdate.new(
        commit_id: source_sha,
        repo_created: false,
        branch_created: false
      )
    end
    let(:response) { Gitaly::UserFFBranchResponse.new(branch_update: branch_update) }

    subject { client.user_ff_branch(user, source_sha, target_branch) }

    it 'sends a user_ff_branch message and returns a BranchUpdate object' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_ff_branch).with(request, kind_of(Hash))
        .and_return(response)

      expect(subject).to be_a(Gitlab::Git::OperationService::BranchUpdate)
      expect(subject.newrev).to eq(source_sha)
      expect(subject.repo_created).to be(false)
      expect(subject.branch_created).to be(false)
    end
  end

  describe '#user_squash' do
    let(:branch_name) { 'my-branch' }
    let(:squash_id) { '1' }
    let(:start_sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
    let(:end_sha) { '54cec5282aa9f21856362fe321c800c236a61615' }
    let(:commit_message) { 'Squash message' }
    let(:request) do
      Gitaly::UserSquashRequest.new(
        repository: repository.gitaly_repository,
        user: gitaly_user,
        squash_id: squash_id.to_s,
        branch: branch_name,
        start_sha: start_sha,
        end_sha: end_sha,
        author: gitaly_user,
        commit_message: commit_message
      )
    end
    let(:squash_sha) { 'f00' }
    let(:response) { Gitaly::UserSquashResponse.new(squash_sha: squash_sha) }

    subject do
      client.user_squash(user, squash_id, branch_name, start_sha, end_sha, user, commit_message)
    end

    it 'sends a user_squash message and returns the squash sha' do
      expect_any_instance_of(Gitaly::OperationService::Stub)
        .to receive(:user_squash).with(request, kind_of(Hash))
        .and_return(response)

      expect(subject).to eq(squash_sha)
    end

    context "when git_error is present" do
      let(:response) do
        Gitaly::UserSquashResponse.new(git_error: "something failed")
      end

      it "throws a PreReceive exception" do
        expect_any_instance_of(Gitaly::OperationService::Stub)
          .to receive(:user_squash).with(request, kind_of(Hash))
          .and_return(response)

        expect { subject }.to raise_error(
          Gitlab::Git::Repository::GitError, "something failed")
      end
    end
  end
end
