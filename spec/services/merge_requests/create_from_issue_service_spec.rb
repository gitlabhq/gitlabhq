# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreateFromIssueService do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:label_ids) { create_pair(:label, project: project).map(&:id) }
  let(:milestone_id) { create(:milestone, project: project).id }
  let(:issue) { create(:issue, project: project, milestone_id: milestone_id) }
  let(:custom_source_branch) { 'custom-source-branch' }
  let(:service) { described_class.new(project: project, current_user: user, mr_params: service_params) }
  let(:service_with_custom_source_branch) { described_class.new(project: project, current_user: user, mr_params: { branch_name: custom_source_branch, **service_params }) }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    shared_examples_for 'a service that creates a merge request from an issue' do
      it 'returns an error when user can not create merge request on target project' do
        result = described_class.new(project: project, current_user: create(:user), mr_params: service_params).execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Not allowed to create merge request')
      end

      it 'returns an error with invalid issue iid' do
        result = described_class.new(project: project, current_user: user, mr_params: { issue_iid: -1 }).execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Invalid issue iid')
      end

      it 'creates a branch based on issue title', :sidekiq_might_not_need_inline do
        service.execute

        expect(target_project.repository.branch_exists?(issue.to_branch_name)).to be_truthy
      end

      it 'creates a branch using passed name', :sidekiq_might_not_need_inline do
        service_with_custom_source_branch.execute

        expect(target_project.repository.branch_exists?(custom_source_branch)).to be_truthy
      end

      it 'creates the new_merge_request system note', :sidekiq_might_not_need_inline do
        expect(SystemNoteService).to receive(:new_merge_request).with(issue, project, user, instance_of(MergeRequest))

        service.execute
      end

      it 'tracks the mr creation when the mr is valid' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_mr_create_from_issue)
          .with(user: user)

        service.execute
      end

      it 'creates the new_issue_branch system note when the branch could be created but the merge_request cannot be created', :sidekiq_might_not_need_inline do
        expect_next_instance_of(MergeRequest) do |instance|
          expect(instance).to receive(:valid?).at_least(:once).and_return(false)
        end

        expect(SystemNoteService).to receive(:new_issue_branch).with(issue, project, user, issue.to_branch_name, branch_project: target_project)

        service.execute
      end

      it 'does not track the mr creation when the Mr is invalid' do
        expect_next_instance_of(MergeRequest) do |instance|
          expect(instance).to receive(:valid?).at_least(:once).and_return(false)
        end

        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to receive(:track_mr_create_from_issue)

        service.execute
      end

      it 'creates a merge request', :sidekiq_might_not_need_inline do
        expect { service.execute }.to change(target_project.merge_requests, :count).by(1)
      end

      it 'sets the merge request author to current user and assigns them', :sidekiq_might_not_need_inline do
        result = service.execute

        expect(result[:merge_request].author).to eq(user)
        expect(result[:merge_request].assignees).to eq([user])
      end

      it 'sets the merge request source branch to the new issue branch', :sidekiq_might_not_need_inline do
        result = service.execute

        expect(result[:merge_request].source_branch).to eq(issue.to_branch_name)
      end

      it 'sets the merge request source branch to the passed branch name', :sidekiq_might_not_need_inline do
        result = service_with_custom_source_branch.execute

        expect(result[:merge_request].source_branch).to eq(custom_source_branch)
      end

      it 'sets the merge request target branch to the project default branch', :sidekiq_might_not_need_inline do
        result = service.execute

        expect(result[:merge_request].target_branch).to eq(target_project.default_branch)
      end

      it 'executes quick actions if the build service sets them in the description', :sidekiq_might_not_need_inline do
        allow(service).to receive(:merge_request).and_wrap_original do |m, *args|
          m.call(*args).tap do |merge_request|
            merge_request.description = "/assign #{user.to_reference}"
          end
        end

        result = service.execute

        expect(result[:merge_request].assignees).to eq([user])
      end

      context 'when ref branch is set', :sidekiq_might_not_need_inline do
        subject { described_class.new(project: project, current_user: user, mr_params: { ref: 'feature', **service_params }).execute }

        it 'sets the merge request source branch to the new issue branch' do
          expect(subject[:merge_request].source_branch).to eq(issue.to_branch_name)
        end

        it 'sets the merge request target branch to the ref branch' do
          expect(subject[:merge_request].target_branch).to eq('feature')
        end

        context 'when the ref is a tag' do
          subject { described_class.new(project: project, current_user: user, mr_params: { ref: 'v1.0.0', **service_params }).execute }

          it 'sets the merge request source branch to the new issue branch' do
            expect(subject[:merge_request].source_branch).to eq(issue.to_branch_name)
          end

          it 'creates a merge request' do
            expect { subject }.to change(target_project.merge_requests, :count).by(1)
          end

          it 'sets the merge request target branch to the project default branch' do
            expect(subject[:merge_request].target_branch).to eq(target_project.default_branch)
          end
        end

        context 'when ref branch does not exist' do
          subject { described_class.new(project: project, current_user: user, mr_params: { ref: 'no-such-branch', **service_params }).execute }

          it 'creates a merge request' do
            expect { subject }.to change(target_project.merge_requests, :count).by(1)
          end

          it 'sets the merge request target branch to the project default branch' do
            expect(subject[:merge_request].target_branch).to eq(target_project.default_branch)
          end
        end
      end
    end

    context 'no target_project_id specified' do
      let(:service_params) { { issue_iid: issue.iid } }
      let(:target_project) { project }

      it_behaves_like 'a service that creates a merge request from an issue'

      it "inherits labels" do
        issue.assign_attributes(label_ids: label_ids)

        result = service.execute

        expect(result[:merge_request].label_ids).to match_array(label_ids)
      end

      it "inherits milestones" do
        result = service.execute

        expect(result[:merge_request].milestone_id).to eq(milestone_id)
      end

      it 'sets the merge request title to: "Draft: Resolves "$issue-title"' do
        result = service.execute

        expect(result[:merge_request].title).to eq("Draft: Resolve \"#{issue.title}\"")
      end
    end

    context 'target_project_id is specified' do
      let(:service_params) { { issue_iid: issue.iid, target_project_id: target_project.id } }

      context 'target project is not a fork of the project' do
        let(:target_project) { create(:project, :repository) }

        it 'returns an error about not finding the project' do
          result = service.execute

          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq('Project not found')
        end

        it 'does not create merge request' do
          expect { service.execute }.to change(target_project.merge_requests, :count).by(0)
        end
      end

      context 'target project is a fork of project project' do
        let(:target_project) { fork_project(project, user, repository: true) }

        it_behaves_like 'a service that creates a merge request from an issue'

        it 'sets the merge request title to: "Draft: $issue-branch-name', :sidekiq_might_not_need_inline do
          result = service.execute

          expect(result[:merge_request].title).to eq("Draft: #{issue.to_branch_name.titleize.humanize}")
        end
      end
    end
  end
end
