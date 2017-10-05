require 'spec_helper'

describe Gitlab::GitalyClient::OperationService do
  let(:project) { create(:project) }
  let(:repository) { project.repository.raw }
  let(:client) { described_class.new(repository) }
  let(:user) { create(:user) }
  let(:gitaly_user) { Gitlab::GitalyClient::Util.gitaly_user(user) }

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
end
