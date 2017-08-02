require 'spec_helper'

describe MergeRequests::CreateFromIssueService do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }
  let(:issue)   { create(:issue, project: project) }

  subject(:service) { described_class.new(project, user, issue_iid: issue.iid) }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    it 'returns an error with invalid issue iid' do
      result = described_class.new(project, user, issue_iid: -1).execute

      expect(result[:status]).to eq :error
      expect(result[:message]).to eq 'Invalid issue iid'
    end

    it 'delegates issue search to IssuesFinder' do
      expect_any_instance_of(IssuesFinder).to receive(:execute).once.and_call_original

      described_class.new(project, user, issue_iid: -1).execute
    end

    it 'delegates the branch creation to CreateBranchService' do
      expect_any_instance_of(CreateBranchService).to receive(:execute).once.and_call_original

      service.execute
    end

    it 'creates a branch based on issue title' do
      service.execute

      expect(project.repository.branch_exists?(issue.to_branch_name)).to be_truthy
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

      expect(result[:merge_request].author).to eq user
    end

    it 'sets the merge request source branch to the new issue branch' do
      result = service.execute

      expect(result[:merge_request].source_branch).to eq issue.to_branch_name
    end

    it 'sets the merge request target branch to the project default branch' do
      result = service.execute

      expect(result[:merge_request].target_branch).to eq project.default_branch
    end
  end
end
