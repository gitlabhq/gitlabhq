require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::IssueStage do
  let(:stage_name) { :issue }
  let(:project) { create(:project) }
  let!(:issue_1) { create(:issue, project: project, created_at: 90.minutes.ago) }
  let!(:issue_2) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let!(:issue_3) { create(:issue, project: project, created_at: 30.minutes.ago) }
  let!(:issue_without_milestone) { create(:issue, project: project, created_at: 1.minute.ago) }
  let(:stage) { described_class.new(project: project, options: { from: 2.days.ago, current_user: project.creator }) }

  before do
    issue_1.metrics.update!(first_associated_with_milestone_at: 60.minutes.ago )
    issue_2.metrics.update!(first_added_to_board_at: 30.minutes.ago)
    issue_3.metrics.update!(first_added_to_board_at: 15.minutes.ago)
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
    it 'exposes issues with metrics' do
      result = stage.events

      expect(result.count).to eq(3)
      expect(result.map { |event| event[:title] }).to contain_exactly(issue_1.title, issue_2.title, issue_3.title)
    end
  end
end
