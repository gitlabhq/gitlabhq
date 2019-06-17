require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::ReviewStage do
  let(:stage_name) { :review }
  let(:project) { create(:project) }
  let!(:issue_1) { create(:issue, project: project, created_at: 90.minutes.ago) }
  let!(:issue_2) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let!(:issue_3) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let!(:mr_1) { create(:merge_request, :closed, source_project: project, created_at: 60.minutes.ago) }
  let!(:mr_2) { create(:merge_request, :closed, source_project: project, created_at: 40.minutes.ago, source_branch: 'A') }
  let!(:mr_3) { create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'B') }
  let!(:mr_4) { create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'C') }
  let(:stage) { described_class.new(project: project, options: { from: 2.days.ago, current_user: project.creator }) }

  before do
    mr_1.metrics.update!(merged_at: 30.minutes.ago)
    mr_2.metrics.update!(merged_at: 10.minutes.ago)

    create(:merge_requests_closing_issues, merge_request: mr_1, issue: issue_1)
    create(:merge_requests_closing_issues, merge_request: mr_2, issue: issue_2)
    create(:merge_requests_closing_issues, merge_request: mr_3, issue: issue_3)
  end

  it_behaves_like 'base stage'

  describe '#median' do
    around do |example|
      Timecop.freeze { example.run }
    end

    it 'counts median from issues with metrics' do
      expect(stage.median).to eq(ISSUES_MEDIAN)
    end
  end

  describe '#events' do
    it 'exposes merge requests that close issues' do
      result = stage.events

      expect(result.count).to eq(2)
      expect(result.map { |event| event[:title] }).to contain_exactly(mr_1.title, mr_2.title)
    end
  end
end
