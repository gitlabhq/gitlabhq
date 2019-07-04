require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::CodeStage do
  let(:stage_name) { :code }

  let(:project) { create(:project) }
  let(:issue_1) { create(:issue, project: project, created_at: 90.minutes.ago) }
  let(:issue_2) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let(:issue_3) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let(:mr_1) { create(:merge_request, source_project: project, created_at: 15.minutes.ago) }
  let(:mr_2) { create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'A') }
  let(:stage) { described_class.new(options: { from: 2.days.ago, current_user: project.creator, project: project }) }

  before do
    issue_1.metrics.update!(first_associated_with_milestone_at: 60.minutes.ago, first_mentioned_in_commit_at: 45.minutes.ago)
    issue_2.metrics.update!(first_added_to_board_at: 60.minutes.ago, first_mentioned_in_commit_at: 40.minutes.ago)
    issue_3.metrics.update!(first_added_to_board_at: 60.minutes.ago, first_mentioned_in_commit_at: 40.minutes.ago)
    create(:merge_request, source_project: project, created_at: 10.minutes.ago, source_branch: 'B')
    create(:merge_requests_closing_issues, merge_request: mr_1, issue: issue_1)
    create(:merge_requests_closing_issues, merge_request: mr_2, issue: issue_2)
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
    it 'exposes merge requests that closes issues' do
      result = stage.events

      expect(result.count).to eq(2)
      expect(result.map { |event| event[:title] }).to contain_exactly(mr_1.title, mr_2.title)
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
    let(:mr_2_1) { create(:merge_request, source_project: project_2, created_at: 15.minutes.ago) }
    let(:mr_2_2) { create(:merge_request, source_project: project_3, created_at: 10.minutes.ago, source_branch: 'A') }
    let(:stage) { described_class.new(options: { from: 2.days.ago, current_user: user, group: group }) }

    before do
      group.add_owner(user)
      issue_2_1.metrics.update!(first_associated_with_milestone_at: 60.minutes.ago, first_mentioned_in_commit_at: 45.minutes.ago)
      issue_2_2.metrics.update!(first_added_to_board_at: 60.minutes.ago, first_mentioned_in_commit_at: 40.minutes.ago)
      issue_2_3.metrics.update!(first_added_to_board_at: 60.minutes.ago, first_mentioned_in_commit_at: 40.minutes.ago)
      create(:merge_requests_closing_issues, merge_request: mr_2_1, issue: issue_2_1)
      create(:merge_requests_closing_issues, merge_request: mr_2_2, issue: issue_2_2)
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
        expect(result.map { |event| event[:title] }).to contain_exactly(mr_2_1.title, mr_2_2.title)
      end
    end

    context 'when subgroup is given' do
      let(:subgroup) { create(:group, parent: group) }
      let(:project_4) { create(:project, group: subgroup) }
      let(:project_5) { create(:project, group: subgroup) }
      let(:issue_3_1) { create(:issue, project: project_4, created_at: 90.minutes.ago) }
      let(:issue_3_2) { create(:issue, project: project_5, created_at: 60.minutes.ago) }
      let(:issue_3_3) { create(:issue, project: project_5, created_at: 60.minutes.ago) }
      let(:mr_3_1) { create(:merge_request, source_project: project_4, created_at: 15.minutes.ago) }
      let(:mr_3_2) { create(:merge_request, source_project: project_5, created_at: 10.minutes.ago, source_branch: 'A') }

      before do
        issue_3_1.metrics.update!(first_associated_with_milestone_at: 60.minutes.ago, first_mentioned_in_commit_at: 45.minutes.ago)
        issue_3_2.metrics.update!(first_added_to_board_at: 60.minutes.ago, first_mentioned_in_commit_at: 40.minutes.ago)
        issue_3_3.metrics.update!(first_added_to_board_at: 60.minutes.ago, first_mentioned_in_commit_at: 40.minutes.ago)
        create(:merge_requests_closing_issues, merge_request: mr_3_1, issue: issue_3_1)
        create(:merge_requests_closing_issues, merge_request: mr_3_2, issue: issue_3_2)
      end

      describe '#events' do
        it 'exposes merge requests that close issues' do
          result = stage.events

          expect(result.count).to eq(4)
          expect(result.map { |event| event[:title] }).to contain_exactly(mr_2_1.title, mr_2_2.title, mr_3_1.title, mr_3_2.title)
        end

        it 'exposes merge requests that close issues with full path for subgroup' do
          result = stage.events

          expect(result.count).to eq(4)
          expect(result.find { |event| event[:title] == mr_3_1.title }[:url]).to include("#{subgroup.full_path}")
        end
      end
    end
  end
end
