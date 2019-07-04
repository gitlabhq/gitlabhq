require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::StagingStage do
  let(:stage_name) { :staging }

  let(:project) { create(:project) }
  let(:issue_1) { create(:issue, project: project, created_at: 90.minutes.ago) }
  let(:issue_2) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let(:issue_3) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let(:mr_1) { create(:merge_request, :closed, source_project: project, created_at: 60.minutes.ago) }
  let(:mr_2) { create(:merge_request, :closed, source_project: project, created_at: 40.minutes.ago, source_branch: 'A') }
  let(:mr_3) { create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'B') }
  let(:build_1) { create(:ci_build, project: project) }
  let(:build_2) { create(:ci_build, project: project) }

  let(:stage) { described_class.new(options: { from: 2.days.ago, current_user: project.creator, project: project }) }

  before do
    mr_1.metrics.update!(merged_at: 80.minutes.ago, first_deployed_to_production_at: 50.minutes.ago, pipeline_id: build_1.commit_id)
    mr_2.metrics.update!(merged_at: 60.minutes.ago, first_deployed_to_production_at: 30.minutes.ago, pipeline_id: build_2.commit_id)
    mr_3.metrics.update!(merged_at: 10.minutes.ago, first_deployed_to_production_at: 3.days.ago, pipeline_id: create(:ci_build, project: project).commit_id)

    create(:merge_requests_closing_issues, merge_request: mr_1, issue: issue_1)
    create(:merge_requests_closing_issues, merge_request: mr_2, issue: issue_2)
    create(:merge_requests_closing_issues, merge_request: mr_3, issue: issue_3)
  end

  it_behaves_like 'base stage'

  describe '#project_median' do
    around do |example|
      Timecop.freeze { example.run }
    end

    it 'counts median from issues with metrics' do
      expect(stage.project_median).to eq(ISSUES_MEDIAN)
    end
  end

  describe '#events' do
    it 'exposes builds connected to merge request' do
      result = stage.events

      expect(result.count).to eq(2)
      expect(result.map { |event| event[:name] }).to contain_exactly(build_1.name, build_2.name)
    end
  end

  context 'when group is given' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:project_2) { create(:project, group: group) }
    let(:project_3) { create(:project, group: group) }
    let(:issue_2_1) { create(:issue, project: project_2, created_at: 90.minutes.ago) }
    let(:issue_2_2) { create(:issue, project: project_3, created_at: 60.minutes.ago) }
    let(:issue_2_3) { create(:issue, project: project_2, created_at: 60.minutes.ago) }
    let(:mr_1) { create(:merge_request, :closed, source_project: project_2, created_at: 60.minutes.ago) }
    let(:mr_2) { create(:merge_request, :closed, source_project: project_3, created_at: 40.minutes.ago, source_branch: 'A') }
    let(:mr_3) { create(:merge_request, source_project: project_2, created_at: 10.minutes.ago, source_branch: 'B') }
    let(:build_1) { create(:ci_build, project: project_2) }
    let(:build_2) { create(:ci_build, project: project_3) }
    let(:stage) { described_class.new(options: { from: 2.days.ago, current_user: user, group: group }) }

    before do
      group.add_owner(user)
      mr_1.metrics.update!(merged_at: 80.minutes.ago, first_deployed_to_production_at: 50.minutes.ago, pipeline_id: build_1.commit_id)
      mr_2.metrics.update!(merged_at: 60.minutes.ago, first_deployed_to_production_at: 30.minutes.ago, pipeline_id: build_2.commit_id)
      mr_3.metrics.update!(merged_at: 10.minutes.ago, first_deployed_to_production_at: 3.days.ago, pipeline_id: create(:ci_build, project: project_2).commit_id)

      create(:merge_requests_closing_issues, merge_request: mr_1, issue: issue_2_1)
      create(:merge_requests_closing_issues, merge_request: mr_2, issue: issue_2_2)
      create(:merge_requests_closing_issues, merge_request: mr_3, issue: issue_2_3)
    end

    describe '#group_median' do
      around do |example|
        Timecop.freeze { example.run }
      end

      it 'counts median from issues with metrics' do
        expect(stage.group_median).to eq(ISSUES_MEDIAN)
      end
    end

    describe '#events' do
      it 'exposes merge requests that close issues' do
        result = stage.events

        expect(result.count).to eq(2)
        expect(result.map { |event| event[:name] }).to contain_exactly(build_1.name, build_2.name)
      end
    end
  end
end
