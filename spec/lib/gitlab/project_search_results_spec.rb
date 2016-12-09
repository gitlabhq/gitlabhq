require 'spec_helper'

describe Gitlab::ProjectSearchResults, lib: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:query) { 'hello world' }

  describe 'initialize with empty ref' do
    let(:results) { Gitlab::ProjectSearchResults.new(user, project, query, '') }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to be_nil }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }
    let(:results) { Gitlab::ProjectSearchResults.new(user, project, query, ref) }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end

  it 'does not list issues on private projects' do
    issue = create(:issue, project: project)

    results = described_class.new(user, project, issue.title)

    expect(results.objects('issues')).not_to include issue
  end

  describe 'confidential issues' do
    let(:query) { 'issue' }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }
    let(:project) { create(:empty_project, :internal) }
    let!(:issue) { create(:issue, project: project, title: 'Issue 1') }
    let!(:security_issue_1) { create(:issue, :confidential, project: project, title: 'Security issue 1', author: author) }
    let!(:security_issue_2) { create(:issue, :confidential, title: 'Security issue 2', project: project, assignee: assignee) }

    it 'does not list project confidential issues for non project members' do
      results = described_class.new(non_member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 1
    end

    it 'does not list project confidential issues for project members with guest role' do
      project.team << [member, :guest]

      results = described_class.new(member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 1
    end

    it 'lists project confidential issues for author' do
      results = described_class.new(author, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).not_to include security_issue_2
      expect(results.issues_count).to eq 2
    end

    it 'lists project confidential issues for assignee' do
      results = described_class.new(assignee, project.id, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).not_to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 2
    end

    it 'lists project confidential issues for project members' do
      project.team << [member, :developer]

      results = described_class.new(member, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 3
    end

    it 'lists all project issues for admin' do
      results = described_class.new(admin, project, query)
      issues = results.objects('issues')

      expect(issues).to include issue
      expect(issues).to include security_issue_1
      expect(issues).to include security_issue_2
      expect(results.issues_count).to eq 3
    end
  end

  describe 'notes search' do
    it 'lists notes' do
      project = create(:empty_project, :public)
      note = create(:note, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).to include note
    end

    it "doesn't list issue notes when access is restricted" do
      project = create(:empty_project, :public, issues_access_level: ProjectFeature::PRIVATE)
      note = create(:note_on_issue, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).not_to include note
    end

    it "doesn't list merge_request notes when access is restricted" do
      project = create(:empty_project, :public, merge_requests_access_level: ProjectFeature::PRIVATE)
      note = create(:note_on_merge_request, project: project)

      results = described_class.new(user, project, note.note)

      expect(results.objects('notes')).not_to include note
    end
  end
end
