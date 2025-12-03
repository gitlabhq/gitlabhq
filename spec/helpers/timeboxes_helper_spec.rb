# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeboxesHelper, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:milestone_expired) { build(:milestone, due_date: Date.today.prev_month) }
  let_it_be(:milestone_closed) { build(:milestone, :closed) }
  let_it_be(:milestone_upcoming) { build(:milestone, start_date: Date.today.next_month) }
  let_it_be(:milestone_open) { build(:milestone) }
  let_it_be(:milestone_closed_and_expired) { build(:milestone, :closed, due_date: Date.today.prev_month) }

  describe '#timebox_date_range' do
    let(:yesterday) { Date.yesterday }
    let(:tomorrow) { yesterday + 2 }
    let(:format) { '%b %-d, %Y' }
    let(:yesterday_formatted) { yesterday.strftime(format) }
    let(:tomorrow_formatted) { tomorrow.strftime(format) }

    context 'milestone' do
      def result_for(*args)
        timebox_date_range(build(:milestone, *args))
      end

      it { expect(result_for(due_date: nil, start_date: nil)).to be_nil }
      it { expect(result_for(due_date: tomorrow)).to eq("expires on #{tomorrow_formatted}") }
      it { expect(result_for(due_date: yesterday)).to eq("expired on #{yesterday_formatted}") }
      it { expect(result_for(start_date: tomorrow)).to eq("starts on #{tomorrow_formatted}") }
      it { expect(result_for(start_date: yesterday)).to eq("started on #{yesterday_formatted}") }
      it { expect(result_for(start_date: yesterday, due_date: tomorrow)).to eq("#{yesterday_formatted}–#{tomorrow_formatted}") }
    end
  end

  describe '#group_milestone_route' do
    let(:group) { build_stubbed(:group) }
    let(:subgroup) { build_stubbed(:group, parent: group, name: 'Test Subgrp') }

    context 'when in subgroup' do
      let(:milestone) { build_stubbed(:group_milestone, group: subgroup) }

      it 'generates correct url despite assigned @group' do
        assign(:group, group)
        milestone_path = "/groups/#{subgroup.full_path}/-/milestones/#{milestone.iid}"
        expect(helper.group_milestone_route(milestone)).to eq(milestone_path)
      end
    end
  end

  describe '#recent_releases_with_counts' do
    let_it_be(:project) { milestone_open.project }
    let_it_be(:user) { create(:user) }

    subject { helper.recent_releases_with_counts(milestone_open, user) }

    before do
      project.add_developer(user)
    end

    it 'returns releases with counts' do
      _old_releases = create_list(:release, 2, project: project, milestones: [milestone_open])
      recent_public_releases = create_list(:release, 3, project: project, milestones: [milestone_open], released_at: '2022-01-01T18:00:00Z')

      is_expected.to match([match_array(recent_public_releases), 5, 2])
    end
  end

  describe '#milestone_releases_tooltip_list' do
    let_it_be(:project) { milestone_upcoming.project }

    it 'returns comma separated list of the names of supplied releases and adds the more count when defined' do
      test_releases = create_list(:release, 3, project: project, milestones: [milestone_upcoming], released_at: '2022-01-01T18:00:00Z')

      releases_list_text = test_releases.map(&:name).join(', ')

      expect(helper.milestone_releases_tooltip_list(test_releases)).to eq(releases_list_text)

      expect(helper.milestone_releases_tooltip_list(test_releases, 7)).to eq("#{releases_list_text}, and 7 more")
    end
  end

  describe '#milestone_status_string' do
    where(:milestone, :status) do
      lazy { milestone_expired }            | 'Expired'
      lazy { milestone_closed }             | 'Closed'
      lazy { milestone_closed_and_expired } | 'Closed'
      lazy { milestone_upcoming }           | 'Upcoming'
      lazy { milestone_open }               | 'Open'
    end

    with_them do
      it 'returns status string' do
        expect(helper.milestone_status_string(milestone)).to eq(status)
      end
    end
  end

  describe '#milestone_badge_variant' do
    where(:milestone, :variant) do
      lazy { milestone_expired }            | :warning
      lazy { milestone_closed }             | :info
      lazy { milestone_closed_and_expired } | :info
      lazy { milestone_upcoming }           | :neutral
      lazy { milestone_open }               | :success
    end

    with_them do
      it 'returns badge variant' do
        expect(helper.milestone_badge_variant(milestone)).to eq(variant)
      end
    end
  end

  describe 'work items feature flag behavior' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:milestone) { create(:milestone, project: project, title: 'Project Milestone') }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      assign(:project, project)
    end

    describe '#milestone_work_items_icon' do
      context 'when work_item_planning_view feature flag is enabled' do
        before do
          stub_feature_flags(work_item_planning_view: true)
        end

        it 'returns work-items icon' do
          expect(helper.milestone_work_items_icon).to eq('work-items')
        end
      end

      context 'when work_item_planning_view feature flag is disabled' do
        before do
          stub_feature_flags(work_item_planning_view: false)
        end

        it 'returns work-item-issue icon' do
          expect(helper.milestone_work_items_icon).to eq('work-item-issue')
        end
      end
    end

    describe '#milestones_issues_path' do
      context 'when work_item_planning_view feature flag is enabled' do
        before do
          stub_feature_flags(work_item_planning_view: true)
        end

        context 'with project' do
          it 'returns project work items path' do
            expect(helper.milestones_issues_path).to eq(project_work_items_path(project))
          end
        end

        context 'with group' do
          let_it_be(:group) { create(:group) }

          before do
            assign(:project, nil)
            assign(:group, group)
          end

          it 'returns group work items path' do
            expect(helper.milestones_issues_path).to eq(group_work_items_path(group))
          end
        end

        context 'when neither project nor group is assigned (dashboard)' do
          before do
            assign(:project, nil)
          end

          it 'returns dashboard issues path' do
            expect(helper.milestones_issues_path).to eq(issues_dashboard_path)
          end
        end
      end

      context 'when work_item_planning_view feature flag is disabled' do
        before do
          stub_feature_flags(work_item_planning_view: false)
        end

        context 'with project' do
          it 'returns project issues path' do
            expect(helper.milestones_issues_path).to eq(project_issues_path(project))
          end
        end

        context 'with group' do
          let_it_be(:group) { create(:group) }

          before do
            assign(:project, nil)
            assign(:group, group)
          end

          it 'returns group issues path' do
            expect(helper.milestones_issues_path).to eq(issues_group_path(group))
          end
        end
      end

      context 'when neither project nor group is assigned (dashboard)' do
        before do
          assign(:project, nil)
        end

        it 'returns dashboard issues path' do
          expect(helper.milestones_issues_path).to eq(issues_dashboard_path)
        end
      end
    end

    describe '#milestones_browse_issuables_path' do
      context 'when work_item_planning_view feature flag is enabled' do
        before do
          stub_feature_flags(work_item_planning_view: true)
        end

        it 'returns work items path for issues type' do
          path = helper.milestones_browse_issuables_path(milestone, type: :issues)
          expect(path).to eq(project_work_items_path(project, milestone_title: milestone.title, state: nil))
        end

        it 'returns work items path for issues type with state' do
          path = helper.milestones_browse_issuables_path(milestone, type: :issues, state: 'closed')
          expect(path).to eq(project_work_items_path(project, milestone_title: milestone.title, state: 'closed'))
        end

        it 'returns merge requests path for merge_requests type' do
          path = helper.milestones_browse_issuables_path(milestone, type: :merge_requests)
          expect(path).to eq(project_merge_requests_path(project, milestone_title: milestone.title, state: nil))
        end
      end

      context 'when work_item_planning_view feature flag is disabled' do
        before do
          stub_feature_flags(work_item_planning_view: false)
        end

        context 'with project' do
          it 'returns issues path for issues type' do
            path = helper.milestones_browse_issuables_path(milestone, type: :issues)
            expect(path).to eq(project_issues_path(project, milestone_title: milestone.title, state: nil))
          end

          it 'returns issues path for issues type with state' do
            path = helper.milestones_browse_issuables_path(milestone, type: :issues, state: 'closed')
            expect(path).to eq(project_issues_path(project, milestone_title: milestone.title, state: 'closed'))
          end

          it 'returns merge requests path for merge_requests type' do
            path = helper.milestones_browse_issuables_path(milestone, type: :merge_requests)
            expect(path).to eq(project_merge_requests_path(project, milestone_title: milestone.title, state: nil))
          end
        end

        context 'with group' do
          let_it_be(:group) { create(:group) }
          let_it_be(:group_milestone) { create(:milestone, group: group, title: 'Group Milestone') }

          before do
            assign(:project, nil)
            assign(:group, group)
          end

          it 'returns group issues path for issues type' do
            path = helper.milestones_browse_issuables_path(group_milestone, type: :issues)
            expect(path).to eq(issues_group_path(group, milestone_title: group_milestone.title, state: nil))
          end

          it 'returns group merge requests path for merge_requests type' do
            path = helper.milestones_browse_issuables_path(group_milestone, type: :merge_requests)
            expect(path).to eq(merge_requests_group_path(group, milestone_title: group_milestone.title, state: nil))
          end
        end
      end

      context 'when neither project nor group is assigned (dashboard)' do
        before do
          assign(:project, nil)
        end

        it 'returns dashboard issues path for issues type' do
          path = helper.milestones_browse_issuables_path(milestone, type: :issues)
          expect(path).to eq(issues_dashboard_path(milestone_title: milestone.title, state: nil))
        end

        it 'returns dashboard merge requests path for merge_requests type' do
          path = helper.milestones_browse_issuables_path(milestone, type: :merge_requests)
          expect(path).to eq(merge_requests_dashboard_path(milestone_title: milestone.title, state: nil))
        end
      end
    end

    describe '#milestone_issues_count_message' do
      before do
        assign(:milestone, milestone)
        allow(milestone).to receive(:issues_visible_to_user).with(user).and_return(instance_double(ActiveRecord::Relation, size: 600))
      end

      context 'when work_item_planning_view feature flag is enabled' do
        before do
          stub_feature_flags(work_item_planning_view: true)
        end

        context 'with project' do
          it 'includes link to work items path' do
            message = helper.milestone_issues_count_message(milestone)
            expect(message).to include('Showing 500 of 600 items.')
            expect(message).to include('View all')
            expect(message).to include(project_work_items_path(project, milestone_title: milestone.title))
          end
        end

        context 'with group' do
          let_it_be(:group) { create(:group) }
          let_it_be(:group_milestone) { create(:milestone, group: group, title: 'Group Milestone') }

          before do
            assign(:project, nil)
            assign(:group, group)
            assign(:milestone, group_milestone)
            allow(group_milestone).to receive(:issues_visible_to_user).with(user).and_return(instance_double(ActiveRecord::Relation, size: 600))
          end

          it 'includes link to group work items path' do
            message = helper.milestone_issues_count_message(group_milestone)
            expect(message).to include('Showing 500 of 600 items.')
            expect(message).to include('View all')
            expect(message).to include(group_work_items_path(group, milestone_title: group_milestone.title))
          end
        end
      end

      context 'when work_item_planning_view feature flag is disabled' do
        before do
          stub_feature_flags(work_item_planning_view: false)
        end

        context 'with project' do
          it 'includes link to issues path' do
            message = helper.milestone_issues_count_message(milestone)
            expect(message).to include('Showing 500 of 600 items.')
            expect(message).to include('View all')
            expect(message).to include(project_issues_path(project, milestone_title: milestone.title))
          end
        end

        context 'with group' do
          let_it_be(:group) { create(:group) }
          let_it_be(:group_milestone) { create(:milestone, group: group, title: 'Group Milestone') }

          before do
            assign(:project, nil)
            assign(:group, group)
            assign(:milestone, group_milestone)
            allow(group_milestone).to receive(:issues_visible_to_user).with(user).and_return(instance_double(ActiveRecord::Relation, size: 600))
          end

          it 'includes link to group issues path' do
            message = helper.milestone_issues_count_message(group_milestone)
            expect(message).to include('Showing 500 of 600 items.')
            expect(message).to include('View all')
            expect(message).to include(issues_group_path(group, milestone_title: group_milestone.title))
          end
        end
      end

      context 'when neither project nor group is assigned (dashboard)' do
        before do
          assign(:project, nil)
        end

        it 'includes link to dashboard issues path' do
          message = helper.milestone_issues_count_message(milestone)
          expect(message).to include('Showing 500 of 600 items.')
          expect(message).to include('View all')
          expect(message).to include(issues_dashboard_path(milestone_title: milestone.title))
        end
      end
    end
  end
end
