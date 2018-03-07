require 'spec_helper'

describe Gitlab::ContributionsCalendar do
  let(:contributor) { create(:user) }
  let(:user) { create(:user) }

  let(:private_project) do
    create(:project, :private) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let(:public_project) do
    create(:project, :public, :repository) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let(:feature_project) do
    create(:project, :public, :issues_private) do |project|
      create(:project_member, user: contributor, project: project).project
    end
  end

  let(:today) { Time.now.utc.to_date }
  let(:yesterday) { today - 1.day }
  let(:tomorrow)  { today + 1.day }
  let(:last_week) { today - 7.days }
  let(:last_year) { today - 1.year }

  before do
    travel_to Time.now.utc.end_of_day
  end

  after do
    travel_back
  end

  def calendar(current_user = nil)
    described_class.new(contributor, current_user)
  end

  def create_event(project, day, hour = 0, action = Event::CREATED, target_symbol = :issue)
    @targets ||= {}
    @targets[project] ||= create(target_symbol, project: project, author: contributor)

    Event.create!(
      project: project,
      action: action,
      target: @targets[project],
      author: contributor,
      created_at: DateTime.new(day.year, day.month, day.day, hour)
    )
  end

  describe '#activity_dates' do
    it "returns a hash of date => count" do
      create_event(public_project, last_week)
      create_event(public_project, last_week)
      create_event(public_project, today)

      expect(calendar.activity_dates).to eq(last_week => 2, today => 1)
    end

    it "only shows private events to authorized users" do
      create_event(private_project, today)
      create_event(feature_project, today)

      expect(calendar.activity_dates[today]).to eq(0)
      expect(calendar(user).activity_dates[today]).to eq(0)
      expect(calendar(contributor).activity_dates[today]).to eq(2)
    end

    it "counts the diff notes on merge request" do
      create_event(public_project, today, 0, Event::COMMENTED, :diff_note_on_merge_request)

      expect(calendar(contributor).activity_dates[today]).to eq(1)
    end

    it "counts the discussions on merge requests and issues" do
      create_event(public_project, today, 0, Event::COMMENTED, :discussion_note_on_merge_request)
      create_event(public_project, today, 2, Event::COMMENTED, :discussion_note_on_issue)

      expect(calendar(contributor).activity_dates[today]).to eq(2)
    end

    context "when events fall under different dates depending on the time zone" do
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
  end

  describe '#events_by_date' do
    it "returns all events for a given date" do
      e1 = create_event(public_project, today)
      e2 = create_event(public_project, today)
      create_event(public_project, last_week)

      expect(calendar.events_by_date(today)).to contain_exactly(e1, e2)
    end

    it "only shows private events to authorized users" do
      e1 = create_event(public_project, today)
      e2 = create_event(private_project, today)
      e3 = create_event(feature_project, today)
      create_event(public_project, last_week)

      expect(calendar.events_by_date(today)).to contain_exactly(e1)
      expect(calendar(contributor).events_by_date(today)).to contain_exactly(e1, e2, e3)
    end

    context 'when the user cannot read read cross project' do
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

  describe '#starting_year' do
    it "should be the start of last year" do
      expect(calendar.starting_year).to eq(last_year.year)
    end
  end

  describe '#starting_month' do
    it "should be the start of this month" do
      expect(calendar.starting_month).to eq(today.month)
    end
  end
end
