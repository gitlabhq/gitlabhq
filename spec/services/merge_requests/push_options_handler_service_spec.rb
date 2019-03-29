# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::PushOptionsHandlerService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:service) { described_class.new(project, user, changes, push_options) }
  let(:source_branch) { 'test' }
  let(:target_branch) { 'feature' }
  let(:new_branch_changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:existing_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:deleted_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 #{Gitlab::Git::BLANK_SHA} refs/heads/#{source_branch}" }
  let(:default_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{project.default_branch}" }

  before do
    project.add_developer(user)
  end

  shared_examples_for 'a service that can create a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'creates a merge request' do
      expect { service.execute }.to change { MergeRequest.count }.by(1)
    end

    it 'sets the correct target branch' do
      branch = push_options[:target] || project.default_branch

      service.execute

      expect(last_mr.target_branch).to eq(branch)
    end

    it 'assigns the MR to the user' do
      service.execute

      expect(last_mr.assignee).to eq(user)
    end

    it 'sets the title and description from the first non-merge commit' do
      commits = project.repository.commits('master', limit: 5)

      expect(Gitlab::Git::Commit).to receive(:between).at_least(:once).and_return(commits)

      service.execute

      merge_commit = commits.first
      non_merge_commit = commits.second

      expect(merge_commit.merge_commit?).to eq(true)
      expect(non_merge_commit.merge_commit?).to eq(false)

      expect(last_mr.title).to eq(non_merge_commit.title)
      expect(last_mr.description).to eq(non_merge_commit.description)
    end
  end

  shared_examples_for 'a service that can set the target of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the target_branch' do
      service.execute

      expect(last_mr.target_branch).to eq(target_branch)
    end
  end

  shared_examples_for 'a service that does not create a merge request' do
    it do
      expect { service.execute }.not_to change { MergeRequest.count }
    end
  end

  shared_examples_for 'a service that does not update a merge request' do
    it do
      expect { service.execute }.not_to change { MergeRequest.maximum(:updated_at) }
    end
  end

  shared_examples_for 'a service that does nothing' do
    include_examples 'a service that does not create a merge request'
    include_examples 'a service that does not update a merge request'
  end

  describe '`create` push option' do
    let(:push_options) { { create: true } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that can create a merge request'
    end

    context 'with an existing branch but no open MR' do
      let(:changes) { existing_branch_changes }

      it_behaves_like 'a service that can create a merge request'
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
    end

    context 'with a deleted branch' do
      let(:changes) { deleted_branch_changes }

      it_behaves_like 'a service that does nothing'
    end

    context 'with the project default branch' do
      let(:changes) { default_branch_changes }

      it_behaves_like 'a service that does nothing'
    end
  end

  describe '`target` push option' do
    let(:push_options) { { target: target_branch } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        error = "A merge_request.create push option is required to create a merge request for branch #{source_branch}"

        service.execute

        expect(service.errors).to include(error)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, target: target_branch } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the target of a merge request'
      end
    end

    context 'with an existing branch but no open MR' do
      let(:changes) { existing_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        error = "A merge_request.create push option is required to create a merge request for branch #{source_branch}"

        service.execute

        expect(service.errors).to include(error)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, target: target_branch } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the target of a merge request'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the target of a merge request'
    end

    context 'with a deleted branch' do
      let(:changes) { deleted_branch_changes }

      it_behaves_like 'a service that does nothing'
    end

    context 'with the project default branch' do
      let(:changes) { default_branch_changes }

      it_behaves_like 'a service that does nothing'
    end
  end

  describe 'multiple pushed branches' do
    let(:push_options) { { create: true } }
    let(:changes) do
      [
        new_branch_changes,
        "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/second-branch"
      ]
    end

    it 'creates a merge request per branch' do
      expect { service.execute }.to change { MergeRequest.count }.by(2)
    end

    context 'when there are too many pushed branches' do
      let(:limit) { MergeRequests::PushOptionsHandlerService::LIMIT }
      let(:changes) do
        TestEnv::BRANCH_SHA.to_a[0..limit].map do |x|
          "#{Gitlab::Git::BLANK_SHA} #{x.first} refs/heads/#{x.last}"
        end
      end

      it 'throws an error' do
        expect { service.execute }.to raise_error(
          MergeRequests::PushOptionsHandlerService::Error,
          "Too many branches pushed (#{limit + 1} were pushed, limit is #{limit})"
        )
      end
    end
  end

  describe 'no push options' do
    let(:push_options) { {} }
    let(:changes) { new_branch_changes }

    it_behaves_like 'a service that does nothing'
  end

  describe 'no user' do
    let(:user) { nil }
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }

    it 'throws an error' do
      expect { service.execute }.to raise_error(
        MergeRequests::PushOptionsHandlerService::Error,
        'User is required'
      )
    end
  end

  describe 'unauthorized user' do
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }

    it 'throws an error' do
      Members::DestroyService.new(user).execute(ProjectMember.find_by!(user_id: user.id))

      expect { service.execute }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  describe 'when target is not a valid branch name' do
    let(:push_options) { { create: true, target: 'my-branch' } }
    let(:changes) { new_branch_changes }

    it 'throws an error' do
      expect { service.execute }.to raise_error(
        MergeRequests::PushOptionsHandlerService::Error,
        'Branch my-branch does not exist'
      )
    end
  end

  describe 'when MRs are not enabled' do
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }

    it 'throws an error' do
      expect(project).to receive(:merge_requests_enabled?).and_return(false)

      expect { service.execute }.to raise_error(
        MergeRequests::PushOptionsHandlerService::Error,
        'Merge requests are not enabled for project'
      )
    end
  end

  describe 'when MR has ActiveRecord errors' do
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }

    it 'adds the error to its errors property' do
      invalid_merge_request = MergeRequest.new
      invalid_merge_request.errors.add(:base, 'my error')

      expect_any_instance_of(
        MergeRequests::CreateService
      ).to receive(:execute).and_return(invalid_merge_request)

      service.execute

      expect(service.errors).to eq(['my error'])
    end
  end
end
