require 'spec_helper'

describe Gitlab::Elastic::SearchResults, lib: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
  end

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
        :issue, project: project_1,
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
      results = described_class.new(limit_project_ids, 'hello world')
      issues = results.objects('issues')

      expect(issues).to include @issue_1
      expect(issues).to include @issue_2
      expect(issues).not_to include @issue_3
      expect(results.issues_count).to eq 2
    end

    it 'should return empty list when issues title or description does not contain the query' do
      results = described_class.new(limit_project_ids, 'security')

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
    end

    it 'should list issue when search by a valid iid' do
      results = described_class.new(limit_project_ids, '#2')
      issues = results.objects('issues')

      expect(issues).not_to include @issue_1
      expect(issues).to include @issue_2
      expect(issues).not_to include @issue_3
      expect(results.issues_count).to eq 1
    end

    it 'should return empty list when search by invalid iid' do
      results = described_class.new(limit_project_ids, '#222')

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
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
      results = described_class.new(limit_project_ids, 'hello world')
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).to include @merge_request_1
      expect(merge_requests).to include @merge_request_2
      expect(merge_requests).not_to include @merge_request_3
      expect(results.merge_requests_count).to eq 2
    end

    it 'should return empty list when merge requests title or description does not contain the query' do
      results = described_class.new(limit_project_ids, 'security')

      expect(results.objects('merge_requests')).to be_empty
      expect(results.merge_requests_count).to eq 0
    end

    it 'should list merge request when search by a valid iid' do
      results = described_class.new(limit_project_ids, '#2')
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).not_to include @merge_request_1
      expect(merge_requests).to include @merge_request_2
      expect(merge_requests).not_to include @merge_request_3
      expect(results.merge_requests_count).to eq 1
    end

    it 'should return empty list when search by invalid iid' do
      results = described_class.new(limit_project_ids, '#222')

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

      result = Gitlab::Elastic::SearchResults.new([project.id], 'term')

      expect(result.issues_count).to eq(2)
      expect(result.merge_requests_count).to eq(2)
      expect(result.milestones_count).to eq(2)
      expect(result.projects_count).to eq(1)
    end
  end
end
