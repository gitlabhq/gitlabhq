require 'spec_helper'

describe Gitlab::SearchResults do
  let(:user) { create(:user) }
  let!(:project) { create(:project, name: 'foo') }
  let!(:issue) { create(:issue, project: project, title: 'foo') }

  let!(:merge_request) do
    create(:merge_request, source_project: project, title: 'foo')
  end

  let!(:milestone) { create(:milestone, project: project, title: 'foo') }
  let(:results) { described_class.new(user, Project.all, 'foo') }

  context 'as a user with access' do
    before do
      project.team << [user, :developer]
    end

    describe '#projects_count' do
      it 'returns the total amount of projects' do
        expect(results.projects_count).to eq(1)
      end
    end

    describe '#issues_count' do
      it 'returns the total amount of issues' do
        expect(results.issues_count).to eq(1)
      end
    end

    describe '#merge_requests_count' do
      it 'returns the total amount of merge requests' do
        expect(results.merge_requests_count).to eq(1)
      end
    end

    describe '#milestones_count' do
      it 'returns the total amount of milestones' do
        expect(results.milestones_count).to eq(1)
      end
    end
  end

  it 'does not list issues on private projects' do
    private_project = create(:empty_project, :private)
    issue = create(:issue, project: private_project, title: 'foo')

    expect(results.objects('issues')).not_to include issue
  end

  describe 'confidential issues' do
    let(:project_1) { create(:empty_project, :internal) }
    let(:project_2) { create(:empty_project, :internal) }
    let(:project_3) { create(:empty_project, :internal) }
    let(:project_4) { create(:empty_project, :internal) }
    let(:query) { 'issue' }
    let(:limit_projects) { Project.where(id: [project_1.id, project_2.id, project_3.id]) }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let!(:issue) { create(:issue, project: project_1, title: 'Issue 1') }
    let!(:security_issue_1) { create(:issue, :confidential, project: project_1, title: 'Security issue 1', author: author) }
    let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project_1, assignee: assignee) }
    let!(:security_issue_3) { create(:issue, :confidential, project: project_2, title: 'Security issue 3', author: author) }
    let!(:security_issue_4) { create(:issue, :confidential, project: project_3, title: 'Security issue 4', assignee: assignee) }
    let!(:security_issue_5) { create(:issue, :confidential, project: project_4, title: 'Security issue 5') }

    it 'does not list confidential issues for non project members' do
      results = described_class.new(non_member, limit_projects, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(issues).not_to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.issues_count).to eq 1
    end

    it 'does not list confidential issues for project members with guest role' do
      project_1.team << [member, :guest]
      project_2.team << [member, :guest]

      results = described_class.new(member, limit_projects, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(issues).not_to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.issues_count).to eq 1
    end

    it 'lists confidential issues for author' do
      results = described_class.new(author, limit_projects, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(issues).to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.issues_count).to eq 3
    end

    it 'lists confidential issues for assignee' do
      results = described_class.new(assignee, limit_projects, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).to include security_issue_2
      expect(issues).not_to include security_issue_3
      expect(issues).to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.issues_count).to eq 3
    end

    it 'lists confidential issues for project members' do
      project_1.team << [member, :developer]
      project_2.team << [member, :developer]

      results = described_class.new(member, limit_projects, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(issues).to include security_issue_3
      expect(issues).not_to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.issues_count).to eq 4
    end

    it 'lists all issues for admin' do
      results = described_class.new(admin, limit_projects, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(issues).to include security_issue_3
      expect(issues).to include security_issue_4
      expect(issues).not_to include security_issue_5
      expect(results.issues_count).to eq 5
    end
  end
end
