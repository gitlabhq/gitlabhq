require 'spec_helper'

describe Gitlab::Elastic::SearchResults, lib: true do
  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  after do
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  let(:user) { create(:user) }
  let(:project_1) { create(:project) }
  let(:project_2) { create(:project) }
  let(:limit_project_ids) { [project_1.id] }

  describe 'issues' do
    before do
      Issue.__elasticsearch__.create_index!

      @issue_1 = create(
        :issue,
        project: project_1,
        title: 'Hello world, here I am!',
        iid: 1
      )
      @issue_2 = create(
        :issue,
        project: project_1,
        title: 'Issue 2',
        description: 'Hello world, here I am!',
        iid: 2
      )
      @issue_3 = create(
        :issue,
        project: project_2,
        title: 'Issue 3',
        iid: 2
      )

      Issue.__elasticsearch__.refresh_index!
    end

    after do
      Issue.__elasticsearch__.delete_index!
    end

    it 'should list issues that title or description contain the query' do
      results = described_class.new(user, limit_project_ids, 'hello world')
      issues = results.objects('issues')

      expect(issues).to include @issue_1
      expect(issues).to include @issue_2
      expect(issues).not_to include @issue_3
      expect(results.issues_count).to eq 2
    end

    it 'should return empty list when issues title or description does not contain the query' do
      results = described_class.new(user, limit_project_ids, 'security')

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
    end

    it 'should list issue when search by a valid iid' do
      results = described_class.new(user, limit_project_ids, '#2')
      issues = results.objects('issues')

      expect(issues).not_to include @issue_1
      expect(issues).to include @issue_2
      expect(issues).not_to include @issue_3
      expect(results.issues_count).to eq 1
    end

    it 'should return empty list when search by invalid iid' do
      results = described_class.new(user, limit_project_ids, '#222')

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
    end
  end

  describe 'confidential issues' do
    let(:project_3) { create(:empty_project) }
    let(:project_4) { create(:empty_project) }
    let(:limit_project_ids) { [project_1.id, project_2.id, project_3.id] }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }

    before do
      Issue.__elasticsearch__.create_index!

      @issue = create(:issue, project: project_1, title: 'Issue 1', iid: 1)
      @security_issue_1 = create(:issue, :confidential, project: project_1, title: 'Security issue 1', author: author, iid: 2)
      @security_issue_2 = create(:issue, :confidential, title: 'Security issue 2', project: project_1, assignee: assignee, iid: 3)
      @security_issue_3 = create(:issue, :confidential, project: project_2, title: 'Security issue 3', author: author, iid: 1)
      @security_issue_4 = create(:issue, :confidential, project: project_3, title: 'Security issue 4', assignee: assignee, iid: 1)
      @security_issue_5 = create(:issue, :confidential, project: project_4, title: 'Security issue 5', iid: 1)

      Issue.__elasticsearch__.refresh_index!
    end

    context 'search by term' do
      let(:query) { 'issue' }

      it 'should not list confidential issues for guests' do
        results = described_class.new(nil, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'should not list confidential issues for non project members' do
        results = described_class.new(non_member, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'should list confidential issues for author' do
        results = described_class.new(author, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      it 'should list confidential issues for assignee' do
        results = described_class.new(assignee, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      it 'should list confidential issues for project members' do
        project_1.team << [member, :developer]
        project_2.team << [member, :developer]

        results = described_class.new(member, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).to include @security_issue_1
        expect(issues).to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 4
      end

      it 'should list all issues for admin' do
        results = described_class.new(admin, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).to include @security_issue_1
        expect(issues).to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 5
      end
    end

    context 'search by iid' do
      let(:query) { '#1' }

      it 'should not list confidential issues for guests' do
        results = described_class.new(nil, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'should not list confidential issues for non project members' do
        results = described_class.new(non_member, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'should list confidential issues for author' do
        results = described_class.new(author, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 2
      end

      it 'should list confidential issues for assignee' do
        results = described_class.new(assignee, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 2
      end

      it 'should list confidential issues for project members' do
        project_2.team << [member, :developer]
        project_3.team << [member, :developer]

        results = described_class.new(member, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      it 'should list all issues for admin' do
        results = described_class.new(admin, limit_project_ids, query)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end
    end
  end

  describe 'merge requests' do
    before do
      MergeRequest.__elasticsearch__.create_index!

      @merge_request_1 = create(
        :merge_request,
        source_project: project_1,
        target_project: project_1,
        title: 'Hello world, here I am!',
        iid: 1
      )
      @merge_request_2 = create(
        :merge_request,
        :conflict,
        source_project: project_1,
        target_project: project_1,
        title: 'Merge Request 2',
        description: 'Hello world, here I am!',
        iid: 2
      )
      @merge_request_3 = create(
        :merge_request,
        source_project: project_2,
        target_project: project_2,
        title: 'Merge Request 3',
        iid: 2
      )

      MergeRequest.__elasticsearch__.refresh_index!
    end

    after do
      MergeRequest.__elasticsearch__.delete_index!
    end

    it 'should list merge requests that title or description contain the query' do
      results = described_class.new(user, limit_project_ids, 'hello world')
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).to include @merge_request_1
      expect(merge_requests).to include @merge_request_2
      expect(merge_requests).not_to include @merge_request_3
      expect(results.merge_requests_count).to eq 2
    end

    it 'should return empty list when merge requests title or description does not contain the query' do
      results = described_class.new(user, limit_project_ids, 'security')

      expect(results.objects('merge_requests')).to be_empty
      expect(results.merge_requests_count).to eq 0
    end

    it 'should list merge request when search by a valid iid' do
      results = described_class.new(user, limit_project_ids, '#2')
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).not_to include @merge_request_1
      expect(merge_requests).to include @merge_request_2
      expect(merge_requests).not_to include @merge_request_3
      expect(results.merge_requests_count).to eq 1
    end

    it 'should return empty list when search by invalid iid' do
      results = described_class.new(user, limit_project_ids, '#222')

      expect(results.objects('merge_requests')).to be_empty
      expect(results.merge_requests_count).to eq 0
    end
  end

  describe 'project scoping' do
    before do
      [Project, MergeRequest, Issue, Milestone].each do |model|
        model.__elasticsearch__.create_index!
      end
    end

    after do
      [Project, MergeRequest, Issue, Milestone].each do |model|
        model.__elasticsearch__.delete_index!
      end
    end

    it "returns items for project" do
      project = create :project, name: "term"

      # Create issue
      create :issue, title: 'bla-bla term', project: project
      create :issue, description: 'bla-bla term', project: project
      create :issue, project: project
      # The issue I have no access to
      create :issue, title: 'bla-bla term'

      # Create Merge Request
      create :merge_request, title: 'bla-bla term', source_project: project
      create :merge_request, description: 'term in description', source_project: project, target_branch: "feature2"
      create :merge_request, source_project: project, target_branch: "feature3"
      # The merge request you have no access to
      create :merge_request, title: 'also with term'

      create :milestone, title: 'bla-bla term', project: project
      create :milestone, description: 'bla-bla term', project: project
      create :milestone, project: project
      # The Milestone you have no access to
      create :milestone, title: 'bla-bla term'

      [Project, MergeRequest, Issue, Milestone].each do |model|
        model.__elasticsearch__.refresh_index!
      end

      result = Gitlab::Elastic::SearchResults.new(user, [project.id], 'term')

      expect(result.issues_count).to eq(2)
      expect(result.merge_requests_count).to eq(2)
      expect(result.milestones_count).to eq(2)
      expect(result.projects_count).to eq(1)
    end
  end
end
