# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ContributionsCalendar, feature_category: :user_profile do
  let_it_be_with_reload(:contributor) { create(:user) }
  let_it_be_with_reload(:user) { create(:user) }
  let(:travel_time) { nil }

  let_it_be_with_reload(:private_project) do
    create(:project, :private) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let_it_be(:public_project) do
    create(:project, :public, :repository) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let_it_be(:public_project_with_private_issues) do
    create(:project, :public, :issues_private) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let(:today) { Time.now.utc.to_date }
  let(:yesterday) { today - 1.day }
  let(:tomorrow)  { today + 1.day }
  let(:last_week) { today - 7.days }
  let(:last_year) { today - 1.year }
  let(:targets) { {} }

  before do
    travel_to travel_time || Time.now.utc.end_of_day
  end

  after do
    travel_back
  end

  def calendar(current_user = nil)
    described_class.new(contributor, current_user)
  end

  def create_event(project, day, hour = 0, action = :created, target_symbol = :issue)
    targets[project] ||=
      if target_symbol == :merge_request
        create(:merge_request, source_project: project, author: contributor)
      else
        create(target_symbol, project: project, author: contributor)
      end

    Event.create!(
      project: project,
      action: action,
      target_type: targets[project].class.name,
      target_id: targets[project].id,
      author: contributor,
      created_at: DateTime.new(day.year, day.month, day.day, hour)
    )
  end

  describe '#activity_dates', :aggregate_failures do
    it 'returns a hash of date => count' do
      create_event(public_project, last_week)
      create_event(public_project, last_week)
      create_event(public_project, today)
      work_item_event = create_event(private_project, today, 0, :created, :work_item)

      # make sure the target is a work item as we want to include those in the count
      expect(work_item_event.target_type).to eq('WorkItem')
      expect(calendar(contributor).activity_dates).to eq(last_week => 2, today => 2)
    end

    context "when the user has opted-in for private contributions" do
      before do
        contributor.update_column(:include_private_contributions, true)
      end

      it "shows private and public events to all users" do
        create_event(private_project, today)
        create_event(public_project, today)

        expect(calendar.activity_dates[today]).to eq(2)
        expect(calendar(user).activity_dates[today]).to eq(2)
        expect(calendar(contributor).activity_dates[today]).to eq(2)
      end

      # tests for bug https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74826
      it "still counts correct with feature access levels set to private" do
        create_event(private_project, today)

        private_project.project_feature.update_attribute(:issues_access_level, ProjectFeature::PRIVATE)
        private_project.project_feature.update_attribute(:repository_access_level, ProjectFeature::PRIVATE)
        private_project.project_feature.update_attribute(:merge_requests_access_level, ProjectFeature::PRIVATE)

        expect(calendar.activity_dates[today]).to eq(1)
        expect(calendar(user).activity_dates[today]).to eq(1)
        expect(calendar(contributor).activity_dates[today]).to eq(1)
      end

      it "does not fail if there are no contributed projects" do
        expect(calendar.activity_dates[today]).to eq(nil)
      end
    end

    it "counts the diff notes on merge request" do
      create_event(public_project, today, 0, :commented, :diff_note_on_merge_request)

      expect(calendar(contributor).activity_dates[today]).to eq(1)
    end

    it "counts the discussions on merge requests and issues" do
      create_event(public_project, today, 0, :commented, :discussion_note_on_merge_request)
      create_event(public_project, today, 2, :commented, :discussion_note_on_issue)

      expect(calendar(contributor).activity_dates[today]).to eq(2)
    end

    it "counts merge request events" do
      create_event(public_project, today, 0, :created, :merge_request)
      create_event(public_project, today, 1, :closed, :merge_request)
      create_event(public_project, today, 2, :approved, :merge_request)
      create_event(public_project, today, 3, :merged, :merge_request)

      expect(calendar(contributor).activity_dates[today]).to eq(4)
    end

    context "when events fall under different dates depending on the system time zone" do
      before do
        create_event(public_project, today, 1)
        create_event(public_project, today, 4)
        create_event(public_project, today, 10)
        create_event(public_project, today, 16)
        create_event(public_project, today, 23)
      end

      it "renders correct event counts within the UTC timezone" do
        Time.use_zone('UTC') do
          expect(calendar.activity_dates).to eq(today => 5)
        end
      end

      it "renders correct event counts within the Sydney timezone" do
        Time.use_zone('Sydney') do
          expect(calendar.activity_dates).to eq(today => 3, tomorrow => 2)
        end
      end

      it "renders correct event counts within the US Central timezone" do
        Time.use_zone('Central Time (US & Canada)') do
          expect(calendar.activity_dates).to eq(yesterday => 2, today => 3)
        end
      end
    end

    context "when events fall under different dates depending on the contributor's time zone" do
      before do
        create_event(public_project, today, 1)
        create_event(public_project, today, 4)
        create_event(public_project, today, 10)
        create_event(public_project, today, 16)
        create_event(public_project, today, 23)
        create_event(public_project, tomorrow, 1)
      end

      it "renders correct event counts within the UTC timezone" do
        Time.use_zone('UTC') do
          contributor.timezone = 'UTC'
          expect(calendar.activity_dates).to eq(today => 5)
        end
      end

      it "renders correct event counts within the Sydney timezone" do
        Time.use_zone('UTC') do
          contributor.timezone = 'Sydney'
          expect(calendar.activity_dates).to eq(today => 3, tomorrow => 3)
        end
      end

      it "renders correct event counts within the US Central timezone" do
        Time.use_zone('UTC') do
          contributor.timezone = 'Central Time (US & Canada)'
          expect(calendar.activity_dates).to eq(yesterday => 2, today => 4)
        end
      end
    end
  end

  describe '#events_by_date' do
    it "returns all events for a given date" do
      e1 = create_event(public_project, today)
      e2 = create_event(public_project, today)
      e3 = create_event(private_project, today, 0, :created, :work_item)
      create_event(public_project, last_week)

      expect([e1, e2, e3].map(&:target_type)).to contain_exactly('WorkItem', 'Issue', 'Issue')
      expect(calendar(contributor).events_by_date(today)).to contain_exactly(e1, e2, e3)
    end

    it "only shows private events to authorized users" do
      e1 = create_event(public_project, today)
      e2 = create_event(private_project, today)
      e3 = create_event(public_project_with_private_issues, today, 0, :created, :issue)
      create_event(public_project, last_week)

      expect(calendar.events_by_date(today)).to contain_exactly(e1)
      expect(calendar(contributor).events_by_date(today)).to contain_exactly(e1, e2, e3)
    end

    it "includes diff notes on merge request" do
      e1 = create_event(public_project, today, 0, :commented, :diff_note_on_merge_request)

      expect(calendar.events_by_date(today)).to contain_exactly(e1)
    end

    it 'includes merge request events' do
      mr_created_event = create_event(public_project, today, 0, :created, :merge_request)
      mr_closed_event = create_event(public_project, today, 1, :closed, :merge_request)
      mr_approved_event = create_event(public_project, today, 2, :approved, :merge_request)
      mr_merged_event = create_event(public_project, today, 3, :merged, :merge_request)

      expect(calendar.events_by_date(today)).to contain_exactly(
        mr_created_event, mr_closed_event, mr_approved_event, mr_merged_event
      )
    end

    context 'when the user cannot read cross project' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
      end

      it 'does not return any events' do
        create_event(public_project, today)

        expect(calendar(user).events_by_date(today)).to be_empty
      end
    end
  end
end
