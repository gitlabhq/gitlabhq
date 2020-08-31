# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::TestStage do
  let(:stage_name) { :test }
  let(:project) { create(:project) }
  let(:stage_options) { { from: 2.days.ago, current_user: project.creator, project: project } }
  let(:stage) { described_class.new(options: stage_options) }

  it_behaves_like 'base stage'

  describe '#median' do
    let(:mr_1) { create(:merge_request, :closed, source_project: project, created_at: 60.minutes.ago) }
    let(:mr_2) { create(:merge_request, :closed, source_project: project, created_at: 40.minutes.ago, source_branch: 'A') }
    let(:mr_3) { create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'B') }
    let(:mr_4) { create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'C') }
    let(:mr_5) { create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'D') }
    let(:ci_build1) { create(:ci_build, project: project) }
    let(:ci_build2) { create(:ci_build, project: project) }

    before do
      issue_1 = create(:issue, project: project, created_at: 90.minutes.ago)
      issue_2 = create(:issue, project: project, created_at: 60.minutes.ago)
      issue_3 = create(:issue, project: project, created_at: 60.minutes.ago)
      mr_1.metrics.update!(latest_build_started_at: 32.minutes.ago, latest_build_finished_at: 2.minutes.ago, pipeline_id: ci_build1.commit_id)
      mr_2.metrics.update!(latest_build_started_at: 62.minutes.ago, latest_build_finished_at: 32.minutes.ago, pipeline_id: ci_build2.commit_id)
      mr_3.metrics.update!(latest_build_started_at: nil, latest_build_finished_at: nil)
      mr_4.metrics.update!(latest_build_started_at: nil, latest_build_finished_at: nil)
      mr_5.metrics.update!(latest_build_started_at: nil, latest_build_finished_at: nil)

      create(:merge_requests_closing_issues, merge_request: mr_1, issue: issue_1)
      create(:merge_requests_closing_issues, merge_request: mr_2, issue: issue_2)
      create(:merge_requests_closing_issues, merge_request: mr_3, issue: issue_3)
      create(:merge_requests_closing_issues, merge_request: mr_4, issue: issue_3)
      create(:merge_requests_closing_issues, merge_request: mr_5, issue: issue_3)
    end

    around do |example|
      freeze_time { example.run }
    end

    it 'counts median from issues with metrics' do
      expect(stage.project_median).to eq(ISSUES_MEDIAN)
    end

    include_examples 'calculate #median with date range'

    context 'when using the new query backend' do
      include_examples 'Gitlab::Analytics::CycleAnalytics::DataCollector backend examples' do
        let(:expected_record_count) { 2 }
        let(:attribute_to_verify) { :id }
        let(:expected_ordered_attribute_values) { [mr_1.metrics.pipeline.builds.first.id, mr_2.metrics.pipeline.builds.first.id] }
      end
    end
  end
end
