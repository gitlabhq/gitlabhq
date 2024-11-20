# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PushOptionsHandlerService, feature_category: :source_code_management do
  include ProjectForksHelper

  let_it_be(:parent_group) { create(:group, :public) }
  let_it_be(:child_group) { create(:group, :public, parent: parent_group) }
  let_it_be(:project) { create(:project, :public, :repository, group: child_group) }
  let_it_be(:user1) { create(:user, developer_of: project) }
  let_it_be(:user2) { create(:user, developer_of: project) }
  let_it_be(:user3) { create(:user, developer_of: project) }
  let_it_be(:forked_project) { fork_project(project, user1, repository: true) }
  let_it_be(:parent_group_milestone) { create(:milestone, group: parent_group, title: 'ParentGroupMilestone1.0') }
  let_it_be(:child_group_milestone) { create(:milestone, group: child_group, title: 'ChildGroupMilestone1.0') }
  let_it_be(:project_milestone) { create(:milestone, project: project, title: 'ProjectMilestone1.0') }

  let(:service) { described_class.new(project: project, current_user: user1, changes: changes, push_options: push_options) }
  let(:source_branch) { 'fix' }
  let(:target_branch) { 'feature' }
  let(:title) { 'my title' }
  let(:draft_title) { 'Draft: my title' }
  let(:draft) { true }
  let(:squash) { true }
  let(:description) { 'my description' }
  let(:multiline_description) do
    <<~MD.chomp
      Line 1
      Line 2
      Line 3
    MD
  end

  let(:label1) { 'mylabel1' }
  let(:label2) { 'mylabel2' }
  let(:label3) { 'mylabel3' }
  let(:new_branch_changes) { "#{Gitlab::Git::SHA1_BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:existing_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:deleted_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 #{Gitlab::Git::SHA1_BLANK_SHA} refs/heads/#{source_branch}" }
  let(:default_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{project.default_branch}" }
  let(:error_mr_required) { "A merge_request.create push option is required to create a merge request for branch #{source_branch}" }

  before do
    stub_licensed_features(multiple_merge_request_assignees: false)
  end

  shared_examples_for 'a service that can set the target of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the target_branch' do
      service.execute

      expect(last_mr.target_branch).to eq(target_branch)
    end
  end

  shared_examples_for 'a service that can set the target project of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'creates a merge request with the correct target project' do
      project_path = push_options[:target_project] || project.default_merge_request_target.full_path

      expect { service.execute }.to change { MergeRequest.count }.by(1)
      expect(last_mr.target_project.full_path).to eq(project_path)
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

  shared_examples_for 'a service that can set the multiline description of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the multiline description' do
      service.execute

      expect(last_mr.description).to eq(multiline_description)
    end
  end

  shared_examples_for 'a service that can set the draft of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the draft' do
      service.execute

      expect(last_mr.draft).to eq(draft)
    end
  end

  shared_examples_for 'a service that can set a merge request to be squashed' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the squash property' do
      service.execute

      expect(last_mr.squash).to eq(squash)
    end
  end

  shared_examples_for 'a service that can set the milestone of a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'sets the milestone' do
      service.execute

      expect(last_mr.milestone&.title).to eq(expected_milestone)
    end
  end

  shared_examples_for 'a service that can set the merge request to merge when pipeline succeeds' do
    subject(:last_mr) { MergeRequest.last }

    let(:change) { Gitlab::ChangesList.new(changes).changes.first }

    it 'sets auto_merge_enabled' do
      service.execute

      expect(last_mr.auto_merge_enabled).to eq(true)
      expect(last_mr.auto_merge_strategy).to eq(AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS)
      expect(last_mr.merge_user).to eq(user1)
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

  shared_examples_for 'a service that does not update a merge request' do
    it do
      expect { service.execute }.not_to change { MergeRequest.maximum(:updated_at) }
    end
  end

  shared_examples_for 'a service that does nothing' do
    include_examples 'a service that does not create a merge request'
    include_examples 'a service that does not update a merge request'
  end

  shared_examples 'with a deleted branch' do
    let(:changes) { deleted_branch_changes }

    it_behaves_like 'a service that does nothing'
  end

  shared_examples 'with the project default branch' do
    let(:changes) { default_branch_changes }

    it_behaves_like 'a service that does nothing'
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
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`merge_when_pipeline_succeeds` push option' do
    let(:push_options) { { merge_when_pipeline_succeeds: true } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
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
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, merge_when_pipeline_succeeds: true } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the merge request to merge when pipeline succeeds'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the merge request to merge when pipeline succeeds'
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`remove_source_branch` push option' do
    let(:push_options) { { remove_source_branch: true } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
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
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, remove_source_branch: true } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can remove the source branch when it is merged'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can remove the source branch when it is merged'
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`target` push option' do
    let(:push_options) { { target: target_branch } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
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
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, target: target_branch } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the target of a merge request'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the target of a merge request'
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`target_project` push option' do
    let(:changes) { new_branch_changes }
    let(:double_forked_project) { fork_project(forked_project, user1, repository: true) }
    let(:service) { described_class.new(project: double_forked_project, current_user: user1, changes: changes, push_options: push_options) }
    let(:push_options) { { create: true, target_project: target_project.full_path } }

    context 'to self' do
      let(:target_project) { double_forked_project }

      it_behaves_like 'a service that can set the target project of a merge request'
    end

    context 'to intermediate project' do
      let(:target_project) { forked_project }

      it_behaves_like 'a service that can set the target project of a merge request'
    end

    context 'to base project' do
      let(:target_project) { project }

      it_behaves_like 'a service that can set the target project of a merge request'
    end
  end

  describe '`title` push option' do
    let(:push_options) { { title: title } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
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
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, title: title } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the title of a merge request'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the title of a merge request'
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`description` push option' do
    let(:push_options) { { description: description } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
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
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, description: description } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the description of a merge request'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the description of a merge request'

      context 'with a multiline description' do
        let(:push_options) { { description: "Line 1\\nLine 2\\nLine 3" } }

        it_behaves_like 'a service that does not create a merge request'
        it_behaves_like 'a service that can set the multiline description of a merge request'
      end
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`draft` push option' do
    let(:push_options) { { draft: draft } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, draft: draft } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the draft of a merge request'
      end
    end

    context 'with an existing branch but no open MR' do
      let(:changes) { existing_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, draft: draft } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the draft of a merge request'
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set the draft of a merge request'
    end

    context 'draft title provided while `draft` push option is set to false' do
      let(:push_options) { { create: true, draft: false, title: draft_title } }
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that can create a merge request'
      it_behaves_like 'a service that can set the draft of a merge request'
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`squash` push option' do
    let(:push_options) { { squash: squash } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, squash: squash } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set a merge request to be squashed'

        context 'when squash is false' do
          let(:squash) { false }

          it_behaves_like 'a service that can set a merge request to be squashed'
        end
      end
    end

    context 'with an existing branch but no open MR' do
      let(:changes) { existing_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, squash: squash } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set a merge request to be squashed'

        context 'when squash is false' do
          let(:squash) { false }

          it_behaves_like 'a service that can set a merge request to be squashed'
        end
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can set a merge request to be squashed'
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`label` push option' do
    let(:push_options) { { label: { label1 => 1, label2 => 1 } } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
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
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, label: { label1 => 1, label2 => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change labels of a merge request', 2
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can change labels of a merge request', 2
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`unlabel` push option' do
    let(:push_options) { { label: { label1 => 1, label2 => 1 }, unlabel: { label1 => 1, label3 => 1 } } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
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
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, label: { label1 => 1, label2 => 1 }, unlabel: { label1 => 1, label3 => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change labels of a merge request', 1
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can change labels of a merge request', 1
    end

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'
  end

  describe '`milestone` push option' do
    context 'with a valid milestone' do
      let(:expected_milestone) { project_milestone.title }
      let(:push_options) { { milestone: project_milestone.title } }

      context 'with a new branch' do
        let(:changes) { new_branch_changes }

        it_behaves_like 'a service that does not create a merge request'

        it 'adds an error to the service' do
          service.execute

          expect(service.errors).to include(error_mr_required)
        end

        context 'when coupled with the `create` push option' do
          let(:push_options) { { create: true, milestone: project_milestone.title } }

          it_behaves_like 'a service that can create a merge request'
          it_behaves_like 'a service that can set the milestone of a merge request'
        end
      end

      context 'with an existing branch but no open MR' do
        let(:changes) { existing_branch_changes }

        it_behaves_like 'a service that does not create a merge request'

        it 'adds an error to the service' do
          service.execute

          expect(service.errors).to include(error_mr_required)
        end

        context 'when coupled with the `create` push option' do
          let(:push_options) { { create: true, milestone: project_milestone.title } }

          it_behaves_like 'a service that can create a merge request'
          it_behaves_like 'a service that can set the milestone of a merge request'
        end
      end

      context 'with an existing branch that has a merge request open' do
        let(:changes) { existing_branch_changes }
        let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

        it_behaves_like 'a service that does not create a merge request'
        it_behaves_like 'a service that can set the milestone of a merge request'
      end

      it_behaves_like 'with a deleted branch'
      it_behaves_like 'with the project default branch'
    end

    context 'with invalid milestone' do
      let(:expected_milestone) { nil }
      let(:changes) { new_branch_changes }
      let(:push_options) { { create: true, milestone: 'invalid_milestone' } }

      it_behaves_like 'a service that can set the milestone of a merge request'
    end

    context 'with an ancestor milestone' do
      let(:changes) { existing_branch_changes }

      context 'with immediate parent milestone' do
        let(:push_options) { { create: true, milestone: child_group_milestone.title } }
        let(:expected_milestone) { child_group_milestone.title }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the milestone of a merge request'
      end

      context 'with multi-level ancestor milestone' do
        let(:push_options) { { create: true, milestone: parent_group_milestone.title } }
        let(:expected_milestone) { parent_group_milestone.title }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can set the milestone of a merge request'
      end
    end
  end

  shared_examples 'with an existing branch that has a merge request open in foss' do
    let(:changes) { existing_branch_changes }
    let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch) }

    it_behaves_like 'a service that does not create a merge request'
    it_behaves_like 'a service that can change assignees of a merge request', 1
  end

  describe '`assign` push option' do
    let(:assigned) { { user2.id => 1, user3.id => 1 } }
    let(:unassigned) { nil }
    let(:push_options) { { assign: assigned, unassign: unassigned } }

    it_behaves_like 'with a new branch', 1
    it_behaves_like 'with an existing branch but no open MR', 1
    it_behaves_like 'with an existing branch that has a merge request open in foss'

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'

    context 'when passing in usernames' do
      # makes sure that usernames starting with numbers aren't treated as IDs
      let(:user2) { create(:user, username: '123user', developer_of: project) }
      let(:user3) { create(:user, username: '999user', developer_of: project) }
      let(:assigned) { { user2.username => 1, user3.username => 1 } }

      it_behaves_like 'with an existing branch that has a merge request open in foss'
    end
  end

  describe '`unassign` push option' do
    let(:assigned) { { user2.id => 1, user3.id => 1 } }
    let(:unassigned) { { user1.id => 1, user3.id => 1 } }
    let(:push_options) { { assign: assigned, unassign: unassigned } }

    it_behaves_like 'with a new branch', 1
    it_behaves_like 'with an existing branch but no open MR', 1
    it_behaves_like 'with an existing branch that has a merge request open in foss'

    it_behaves_like 'with a deleted branch'
    it_behaves_like 'with the project default branch'

    context 'when passing in usernames' do
      let(:assigned) { { user2.username => 1, user3.username => 1 } }
      let(:unassigned) { { user1.username => 1, user3.username => 1 } }

      it_behaves_like 'with an existing branch that has a merge request open in foss'
    end
  end

  describe 'multiple pushed branches' do
    let(:push_options) { { create: true } }
    let(:changes) do
      [
        new_branch_changes,
        "#{Gitlab::Git::SHA1_BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/feature_conflict"
      ]
    end

    it 'creates a merge request per branch' do
      expect { service.execute }.to change { MergeRequest.count }.by(2)
    end

    context 'when there are too many pushed branches' do
      let(:limit) { MergeRequests::PushOptionsHandlerService::LIMIT }
      let(:changes) do
        TestEnv::BRANCH_SHA.to_a[0..limit].map do |x|
          "#{Gitlab::Git::SHA1_BLANK_SHA} #{x.first} refs/heads/#{x.last}"
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
    let(:user1) { nil }
    let(:user2) { nil }
    let(:user3) { nil }
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

    it 'records an error', :sidekiq_inline do
      Members::DestroyService.new(user1).execute(ProjectMember.find_by!(user_id: user1.id))

      service.execute

      expect(service.errors).to eq(['User access was denied'])
    end
  end

  describe 'handling unexpected exceptions' do
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }
    let(:exception) { StandardError.new('My standard error') }

    def run_service_with_exception
      allow_next_instance_of(MergeRequests::BuildService) do |instance|
        allow(instance).to receive(:execute).and_raise(exception)
      end

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

      expect(service.errors).to eq(["Target branch #{project.full_path}:my-branch does not exist"])
    end
  end

  describe 'when the target project does not exist' do
    let(:push_options) { { create: true, target: 'my-branch', target_project: 'does-not-exist' } }
    let(:changes) { default_branch_changes }

    it 'records an error', :sidekiq_inline do
      service.execute

      expect(service.errors).to eq(["User access was denied"])
    end
  end

  describe 'when user does not have access to target project' do
    let(:push_options) { { create: true, target: 'my-branch' } }
    let(:changes) { default_branch_changes }

    before do
      allow(user1).to receive(:can?).with(:read_code, project).and_return(false)
    end

    it 'records an error', :sidekiq_inline do
      service.execute

      expect(service.errors).to eq(["User access was denied"])
    end
  end

  describe 'when MRs are not enabled' do
    let(:project) { create(:project, :public, :repository, developers: user1) }
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }

    it 'records an error' do
      expect(project).to receive(:merge_requests_enabled?).and_return(false)

      service.execute

      expect(service.errors).to eq(["Merge requests are not enabled for project #{project.full_path}"])
    end
  end

  describe 'when projects are unrelated' do
    let(:unrelated_project) { create(:project, :public, :repository, group: child_group) }
    let(:push_options) { { create: true, target_project: unrelated_project.full_path } }
    let(:changes) { new_branch_changes }

    it 'records an error' do
      service.execute

      expect(service.errors).to eq(["Projects #{project.full_path} and #{unrelated_project.full_path} are not in the same network"])
    end
  end

  describe 'when MR has ActiveRecord errors' do
    let(:push_options) { { create: true } }
    let(:changes) { new_branch_changes }

    it 'adds the error to its errors property' do
      invalid_merge_request = MergeRequest.new
      invalid_merge_request.errors.add(:base, 'my error')

      expect_next_instance_of(MergeRequests::CreateService) do |instance|
        expect(instance).to receive(:execute).and_return(invalid_merge_request)
      end

      service.execute

      expect(service.errors).to eq(['my error'])
    end
  end
end
