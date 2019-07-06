require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_stage_spec'

describe Gitlab::CycleAnalytics::IssueStage do
  let(:stage_name) { :issue }
  let(:project) { create(:project) }
  let(:issue_1) { create(:issue, project: project, created_at: 90.minutes.ago) }
  let(:issue_2) { create(:issue, project: project, created_at: 60.minutes.ago) }
  let(:issue_3) { create(:issue, project: project, created_at: 30.minutes.ago) }
  let!(:issue_without_milestone) { create(:issue, project: project, created_at: 1.minute.ago) }
  let(:stage) { described_class.new(options: { from: 2.days.ago, current_user: project.creator, project: project }) }

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
      expect(stage.project_median).to eq(ISSUES_MEDIAN)
    end
  end

  describe '#events' do
    it 'exposes issues with metrics' do
      result = stage.events

      expect(result.count).to eq(3)
      expect(result.map { |event| event[:title] }).to contain_exactly(issue_1.title, issue_2.title, issue_3.title)
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
    let(:stage) { described_class.new(options: { from: 2.days.ago, current_user: user, group: group }) }

    before do
      group.add_owner(user)
      issue_2_1.metrics.update!(first_associated_with_milestone_at: 60.minutes.ago)
      issue_2_2.metrics.update!(first_added_to_board_at: 30.minutes.ago)
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
      subject { stage.events }

      it 'exposes merge requests that close issues' do
        expect(subject.count).to eq(2)
        expect(subject.map { |event| event[:title] }).to contain_exactly(issue_2_1.title, issue_2_2.title)
      end
    end

    context 'when only part of projects is chosen' do
      let(:stage) { described_class.new(options: { from: 2.days.ago, current_user: user, group: group, projects: [project_2.id] }) }

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

          expect(result.count).to eq(1)
          expect(result.map { |event| event[:title] }).to contain_exactly(issue_2_1.title)
        end
      end
    end

    context 'when subgroup is given' do
      let(:subgroup) { create(:group, parent: group) }
      let(:project_4) { create(:project, group: subgroup) }
      let(:project_5) { create(:project, group: subgroup) }
      let(:issue_3_1) { create(:issue, project: project_4, created_at: 90.minutes.ago) }
      let(:issue_3_2) { create(:issue, project: project_5, created_at: 60.minutes.ago) }
      let(:issue_3_3) { create(:issue, project: project_5, created_at: 60.minutes.ago) }

      before do
        issue_3_1.metrics.update!(first_associated_with_milestone_at: 60.minutes.ago)
        issue_3_2.metrics.update!(first_added_to_board_at: 30.minutes.ago)
      end

      describe '#events' do
        subject { stage.events }

        it 'exposes merge requests that close issues' do
          expect(subject.count).to eq(4)
          expect(subject.map { |event| event[:title] }).to contain_exactly(issue_2_1.title, issue_2_2.title, issue_3_1.title, issue_3_2.title)
        end

        it 'exposes merge requests that close issues with full path for subgroup' do
          expect(subject.count).to eq(4)
          expect(subject.find { |event| event[:title] == issue_3_1.title }[:url]).to include("#{subgroup.full_path}")
        end
      end
    end
  end
end
