require 'spec_helper'

describe MergeRequests::CreateFromIssueService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:label_ids) { create_pair(:label, project: project).map(&:id) }
  let(:milestone_id) { create(:milestone, project: project).id }
  let(:issue) { create(:issue, project: project, milestone_id: milestone_id) }
  let(:custom_source_branch) { 'custom-source-branch' }

  subject(:service) { described_class.new(project, user, issue_iid: issue.iid) }
  subject(:service_with_custom_source_branch) { described_class.new(project, user, issue_iid: issue.iid, branch_name: custom_source_branch) }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    it 'returns an error with invalid issue iid' do
      result = described_class.new(project, user, issue_iid: -1).execute

      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Invalid issue iid')
    end

    it 'delegates issue search to IssuesFinder' do
      expect_any_instance_of(IssuesFinder).to receive(:find_by).once.and_call_original

      described_class.new(project, user, issue_iid: -1).execute
    end

    it "inherits labels" do
      issue.assign_attributes(label_ids: label_ids)

      result = service.execute

      expect(result[:merge_request].label_ids).to eq(label_ids)
    end

    it "inherits milestones" do
      result = service.execute

      expect(result[:merge_request].milestone_id).to eq(milestone_id)
    end

    it 'delegates the branch creation to CreateBranchService' do
      expect_any_instance_of(CreateBranchService).to receive(:execute).once.and_call_original

      service.execute
    end

    it 'creates a branch based on issue title' do
      service.execute

      expect(project.repository.branch_exists?(issue.to_branch_name)).to be_truthy
    end

    it 'creates a branch using passed name' do
      service_with_custom_source_branch.execute

      expect(project.repository.branch_exists?(custom_source_branch)).to be_truthy
    end

    it 'creates a system note' do
      expect(SystemNoteService).to receive(:new_issue_branch).with(issue, project, user, issue.to_branch_name)

      service.execute
    end

    it 'creates a merge request' do
      expect { service.execute }.to change(project.merge_requests, :count).by(1)
    end

    it 'sets the merge request title to: "WIP: Resolves "$issue-title"' do
      result = service.execute

      expect(result[:merge_request].title).to eq("WIP: Resolve \"#{issue.title}\"")
    end

    it 'sets the merge request author to current user' do
      result = service.execute

      expect(result[:merge_request].author).to eq(user)
    end

    it 'sets the merge request source branch to the new issue branch' do
      result = service.execute

      expect(result[:merge_request].source_branch).to eq(issue.to_branch_name)
    end

    it 'sets the merge request source branch to the passed branch name' do
      result = service_with_custom_source_branch.execute

      expect(result[:merge_request].source_branch).to eq(custom_source_branch)
    end

    it 'sets the merge request target branch to the project default branch' do
      result = service.execute

      expect(result[:merge_request].target_branch).to eq(project.default_branch)
    end

    it 'executes quick actions if the build service sets them in the description' do
      allow(service).to receive(:merge_request).and_wrap_original do |m, *args|
        m.call(*args).tap do |merge_request|
          merge_request.description = "/assign #{user.to_reference}"
        end
      end

      result = service.execute

      expect(result[:merge_request].assignee).to eq(user)
    end

    context 'when ref branch is set' do
      subject { described_class.new(project, user, issue_iid: issue.iid, ref: 'feature').execute }

      it 'sets the merge request source branch to the new issue branch' do
        expect(subject[:merge_request].source_branch).to eq(issue.to_branch_name)
      end

      it 'sets the merge request target branch to the ref branch' do
        expect(subject[:merge_request].target_branch).to eq('feature')
      end

      context 'when ref branch does not exist' do
        it 'does not create a merge request' do
          expect { described_class.new(project, user, issue_iid: issue.iid, ref: 'nobr').execute }
            .not_to change { project.merge_requests.count }
        end
      end
    end
  end
end
