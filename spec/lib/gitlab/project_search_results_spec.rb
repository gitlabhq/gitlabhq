require 'spec_helper'

describe Gitlab::ProjectSearchResults, lib: true do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:query) { 'hello world' }

  describe 'initialize with empty ref' do
    let(:results) { described_class.new(user, project, query, '') }

    it { expect(results.project).to eq(project) }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'initialize with ref' do
    let(:ref) { 'refs/heads/test' }
    let(:results) { described_class.new(user, project, query, ref) }

    it { expect(results.project).to eq(project) }
    it { expect(results.repository_ref).to eq(ref) }
    it { expect(results.query).to eq('hello world') }
  end

  describe 'blob search' do
    let(:results) { described_class.new(user, project, 'files').objects('blobs') }

    it 'finds by name' do
      expect(results).to include(["files/images/wm.svg", nil])
    end

    it 'finds by content' do
      blob = results.select { |result| result.first == "CHANGELOG" }.flatten.last

      expect(blob.filename).to eq("CHANGELOG")
    end

    describe 'parsing results' do
      let(:results) { project.repository.search_files_by_content('feature', 'master') }
      let(:search_result) { results.first }

      subject { described_class.parse_search_result(search_result) }

      it "returns a valid OpenStruct object" do
        is_expected.to be_an OpenStruct
        expect(subject.filename).to eq('CHANGELOG')
        expect(subject.basename).to eq('CHANGELOG')
        expect(subject.ref).to eq('master')
        expect(subject.startline).to eq(188)
        expect(subject.data.lines[2]).to eq("  - Feature: Replace teams with group membership\n")
      end

      context "when filename has extension" do
        let(:search_result) { "master:CONTRIBUTE.md:5:- [Contribute to GitLab](#contribute-to-gitlab)\n" }

        it { expect(subject.filename).to eq('CONTRIBUTE.md') }
        it { expect(subject.basename).to eq('CONTRIBUTE') }
      end

      context "when file under directory" do
        let(:search_result) { "master:a/b/c.md:5:a b c\n" }

        it { expect(subject.filename).to eq('a/b/c.md') }
        it { expect(subject.basename).to eq('a/b/c') }
      end
    end
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
      results = described_class.new(assignee, project, query)
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
end
