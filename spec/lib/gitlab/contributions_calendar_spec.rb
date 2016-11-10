require 'spec_helper'

describe Gitlab::ContributionsCalendar do
  let(:contributor) { create(:user) }
  let(:user) { create(:user) }

  let(:private_project) do
    create(:empty_project, :private) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let(:public_project) do
    create(:empty_project, :public) do |project|
      create(:project_member, user: contributor, project: project)
    end
  end

  let(:feature_project) do
    create(:empty_project, :public, issues_access_level: ProjectFeature::PRIVATE) do |project|
      create(:project_member, user: contributor, project: project).project
    end
  end

  let(:today) { Time.now.to_date }
  let(:last_week) { today - 7.days }
  let(:last_year) { today - 1.year }

  before do
    travel_to today
  end

  after do
    travel_back
  end

  def calendar(current_user = nil)
    described_class.new(contributor, current_user)
  end

  def create_event(project, day)
    @targets ||= {}
    @targets[project] ||= create(:issue, project: project, author: contributor)

    Event.create!(
      project: project,
      action: Event::CREATED,
      target: @targets[project],
      author: contributor,
      created_at: day,
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
