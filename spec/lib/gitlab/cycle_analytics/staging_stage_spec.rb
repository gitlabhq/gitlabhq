require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::StagingStage do
  let(:stage_name) { :staging }

  let(:project) { create(:project) }
  let!(:issue_1) { create(:issue, project: project, created_at: 90.minutes.ago) }
  let!(:issue_2) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let!(:issue_3) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let!(:mr_1) { create(:merge_request, :closed, source_project: project, created_at: 60.minutes.ago) }
  let!(:mr_2) { create(:merge_request, :closed, source_project: project, created_at: 40.minutes.ago, source_branch: 'A') }
  let!(:mr_3) { create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'B') }
  let(:build_1) { create(:ci_build, project: project) }
  let(:build_2) { create(:ci_build, project: project) }

  let(:stage) { described_class.new(project: project, options: { from: 2.days.ago, current_user: project.creator }) }

  before do
    mr_1.metrics.update!(merged_at: 80.minutes.ago, first_deployed_to_production_at: 50.minutes.ago, pipeline_id: build_1.commit_id)
    mr_2.metrics.update!(merged_at: 60.minutes.ago, first_deployed_to_production_at: 30.minutes.ago, pipeline_id: build_2.commit_id)
    mr_3.metrics.update!(merged_at: 10.minutes.ago, first_deployed_to_production_at: 3.days.ago, pipeline_id: create(:ci_build, project: project).commit_id)

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
    it 'exposes builds connected to merge request' do
      result = stage.events

      expect(result.count).to eq(2)
      expect(result.map { |event| event[:name] }).to contain_exactly(build_1.name, build_2.name)
    end
  end
end
