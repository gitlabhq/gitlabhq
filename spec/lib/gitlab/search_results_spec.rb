require 'spec_helper'

describe Gitlab::SearchResults do
  let!(:project) { create(:project, name: 'foo') }
  let!(:issue) { create(:issue, project: project, title: 'foo') }

  let!(:merge_request) do
    create(:merge_request, source_project: project, title: 'foo')
  end

  let!(:milestone) { create(:milestone, project: project, title: 'foo') }
  let(:results) { described_class.new(Project.all, 'foo') }

  describe '#total_count' do
    it 'returns the total amount of search hits' do
      expect(results.total_count).to eq(4)
    end
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

  describe '#empty?' do
    it 'returns true when there are no search results' do
      allow(results).to receive(:total_count).and_return(0)

      expect(results.empty?).to eq(true)
    end

    it 'returns false when there are search results' do
      expect(results.empty?).to eq(false)
    end
  end
end
