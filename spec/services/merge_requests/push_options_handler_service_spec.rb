# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::PushOptionsHandlerService do
  include ProjectForksHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:forked_project) { fork_project(project, user, repository: true) }
  let(:service) { described_class.new(project, user, changes, push_options) }
  let(:source_branch) { 'fix' }
  let(:target_branch) { 'feature' }
  let(:title) { 'my title' }
  let(:description) { 'my description' }
  let(:label1) { 'mylabel1' }
  let(:label2) { 'mylabel2' }
  let(:label3) { 'mylabel3' }
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

      expect(last_mr.assignees).to contain_exactly(user)
    end

    context 'when project has been forked', :sidekiq_might_not_need_inline do
      let(:forked_project) { fork_project(project, user, repository: true) }
      let(:service) { described_class.new(forked_project, user, changes, push_options) }

      before do
        allow(forked_project).to receive(:empty_repo?).and_return(false)
      end

      it 'sets the correct source project' do
        service.execute

        expect(last_mr.source_project).to eq(forked_project)
      end

      it 'sets the correct target project' do
        service.execute

        expect(last_mr.target_project).to eq(project)
      end
    end
  end

  shared_examples_for 'a service that can set the target of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the target_branch' do
      service.execute

      expect(last_mr.target_branch).to eq(target_branch)
    end
  end

  shared_examples_for 'a service that can set the title of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the title' do
      service.execute

      expect(last_mr.title).to eq(title)
    end
  end

  shared_examples_for 'a service that can set the description of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the description' do
      service.execute

      expect(last_mr.description).to eq(description)
    end
  end

  shared_examples_for 'a service that can set the merge request to merge when pipeline succeeds' do
    subject(:last_mr) { MergeRequest.last }

    let(:change) { Gitlab::ChangesList.new(changes).changes.first }

    it 'sets auto_merge_enabled' do
      service.execute

      expect(last_mr.auto_merge_enabled).to eq(true)
      expect(last_mr.auto_merge_strategy).to eq(AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS)
      expect(last_mr.merge_user).to eq(user)
      expect(last_mr.merge_params['sha']).to eq(change[:newrev])
    end
  end

  shared_examples_for 'a service that can remove the source branch when it is merged' do
    subject(:last_mr) { MergeRequest.last }

    it 'returns true to force_remove_source_branch?' do
      service.execute

      expect(last_mr.force_remove_source_branch?).to eq(true)
    end
  end

  shared_examples_for 'a service that can change labels of a merge request' do |count|
    subject(:last_mr) { MergeRequest.last }

    it 'changes label count' do
      service.execute

      expect(last_mr.label_ids.count).to eq(count)
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

  describe '`merge_when_pipeline_succeeds` push option' do
    let(:push_options) { { merge_when_pipeline_succeeds: true } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        error = "A merge_request.create push option is required to create a merge request for branch #{source_branch}"

        service.execute

        expect(service.errors).to include(error)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, merge_when_pipeline_succeeds: true } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the merge request to merge when pipeline succeeds'
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
        let(:push_options) { { create: true, merge_when_pipeline_succeeds: true } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the merge request to merge when pipeline succeeds'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the merge request to merge when pipeline succeeds'
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

  describe '`remove_source_branch` push option' do
    let(:push_options) { { remove_source_branch: true } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        error = "A merge_request.create push option is required to create a merge request for branch #{source_branch}"

        service.execute

        expect(service.errors).to include(error)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, remove_source_branch: true } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can remove the source branch when it is merged'
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
        let(:push_options) { { create: true, remove_source_branch: true } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can remove the source branch when it is merged'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can remove the source branch when it is merged'
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

  describe '`title` push option' do
    let(:push_options) { { title: title } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        error = "A merge_request.create push option is required to create a merge request for branch #{source_branch}"

        service.execute

        expect(service.errors).to include(error)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, title: title } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the title of a merge request'
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
        let(:push_options) { { create: true, title: title } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the title of a merge request'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the title of a merge request'
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

  describe '`description` push option' do
    let(:push_options) { { description: description } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        error = "A merge_request.create push option is required to create a merge request for branch #{source_branch}"

        service.execute

        expect(service.errors).to include(error)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, description: description } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the description of a merge request'
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
        let(:push_options) { { create: true, description: description } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the description of a merge request'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the description of a merge request'
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

  describe '`label` push option' do
    let(:push_options) { { label: { label1 => 1, label2 => 1 } } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        error = "A merge_request.create push option is required to create a merge request for branch #{source_branch}"

        service.execute

        expect(service.errors).to include(error)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, label: { label1 => 1, label2 => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change labels of a merge request', 2
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
        let(:push_options) { { create: true, label: { label1 => 1, label2 => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change labels of a merge request', 2
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can change labels of a merge request', 2
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

  describe '`unlabel` push option' do
    let(:push_options) { { label: { label1 => 1, label2 => 1 }, unlabel: { label1 => 1, label3 => 1 } } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        error = "A merge_request.create push option is required to create a merge request for branch #{source_branch}"

        service.execute

        expect(service.errors).to include(error)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, label: { label1 => 1, label2 => 1 }, unlabel: { label1 => 1, label3 => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change labels of a merge request', 1
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
        let(:push_options) { { create: true, label: { label1 => 1, label2 => 1 }, unlabel: { label1 => 1, label3 => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change labels of a merge request', 1
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can change labels of a merge request', 1
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
        "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/feature_conflict"
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

      it 'records an error' do
        service.execute

        expect(service.errors).to eq(["Too many branches pushed (#{limit + 1} were pushed, limit is #{limit})"])
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

    it 'records an error' do
      service.execute

      expect(service.errors).to eq(['User is required'])
    end
  end

  describe 'unauthorized user' do
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }

    it 'records an error' do
      Members::DestroyService.new(user).execute(ProjectMember.find_by!(user_id: user.id))

      service.execute

      expect(service.errors).to eq(['User access was denied'])
    end
  end

  describe 'handling unexpected exceptions' do
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }
    let(:exception) { StandardError.new('My standard error') }

    def run_service_with_exception
      allow_any_instance_of(
        MergeRequests::BuildService
      ).to receive(:execute).and_raise(exception)

      service.execute
    end

    it 'records an error' do
      run_service_with_exception

      expect(service.errors).to eq(['An unknown error occurred'])
    end

    it 'writes to Gitlab::AppLogger' do
      expect(Gitlab::AppLogger).to receive(:error).with(exception)

      run_service_with_exception
    end
  end

  describe 'when target is not a valid branch name' do
    let(:push_options) { { create: true, target: 'my-branch' } }
    let(:changes) { new_branch_changes }

    it 'records an error' do
      service.execute

      expect(service.errors).to eq(['Branch my-branch does not exist'])
    end
  end

  describe 'when MRs are not enabled' do
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }

    it 'records an error' do
      expect(project).to receive(:merge_requests_enabled?).and_return(false)

      service.execute

      expect(service.errors).to eq(["Merge requests are not enabled for project #{project.full_path}"])
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
