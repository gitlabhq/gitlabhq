require 'spec_helper'

describe Gitlab::Elastic::SearchResults, lib: true do
  before do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(true)
    Issue.__elasticsearch__.create_index!
    MergeRequest.__elasticsearch__.create_index!
  end

  after do
    allow(Gitlab.config.elasticsearch).to receive(:enabled).and_return(false)
    Issue.__elasticsearch__.delete_index!
    MergeRequest.__elasticsearch__.delete_index!
  end

  let(:project_1) { create(:project) }
  let(:project_2) { create(:project) }
  let(:limit_project_ids) { [project_1.id] }

  describe 'issues' do
    let!(:issue_1) { create(:issue, project: project_1, title: 'Hello world, here I am!', iid: 1) }
    let!(:issue_2) { create(:issue, project: project_1, title: 'Issue 2', description: 'Hello world, here I am!', iid: 2) }
    let!(:issue_3) { create(:issue, project: project_2, title: 'Issue 3', iid: 2) }

    before do
      Issue.__elasticsearch__.refresh_index!
    end

    it 'should list issues that title or description contain the query' do
      results = described_class.new(limit_project_ids, 'hello world')
      issues = results.objects('issues')

      expect(issues).to include issue_1
      expect(issues).to include issue_2
      expect(issues).not_to include issue_3
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

      expect(issues).not_to include issue_1
      expect(issues).to include issue_2
      expect(issues).not_to include issue_3
      expect(results.issues_count).to eq 1
    end

    it 'should return empty list when search by invalid iid' do
      results = described_class.new(limit_project_ids, '#222')

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
    end
  end

  describe 'merge requests' do
    let!(:merge_request_1) { create(:merge_request, source_project: project_1, target_project: project_1, title: 'Hello world, here I am!', iid: 1) }
    let!(:merge_request_2) { create(:merge_request, :conflict, source_project: project_1, target_project: project_1, title: 'Merge Request 2', description: 'Hello world, here I am!', iid: 2) }
    let!(:merge_request_3) { create(:merge_request, source_project: project_2, target_project: project_2, title: 'Merge Request 3', iid: 2) }

    before do
      MergeRequest.__elasticsearch__.refresh_index!
    end

    it 'should list merge requests that title or description contain the query' do
      results = described_class.new(limit_project_ids, 'hello world')
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).to include merge_request_1
      expect(merge_requests).to include merge_request_2
      expect(merge_requests).not_to include merge_request_3
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

      expect(merge_requests).not_to include merge_request_1
      expect(merge_requests).to include merge_request_2
      expect(merge_requests).not_to include merge_request_3
      expect(results.merge_requests_count).to eq 1
    end

    it 'should return empty list when search by invalid iid' do
      results = described_class.new(limit_project_ids, '#222')

      expect(results.objects('merge_requests')).to be_empty
      expect(results.merge_requests_count).to eq 0
    end
  end
end
