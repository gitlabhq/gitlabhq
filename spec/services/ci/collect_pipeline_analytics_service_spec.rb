# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::CollectPipelineAnalyticsService, :click_house, :enable_admin_mode,
  feature_category: :fleet_visibility do
  include ClickHouseHelpers

  let_it_be(:project1) { create(:project).tap(&:reload) } # reload required to calculate traversal path
  let_it_be(:project2) { create(:project).tap(&:reload) }
  let_it_be(:current_user) { create(:user, reporter_of: [project1, project2]) }

  let_it_be(:starting_time) { Time.utc(2023) }
  let_it_be(:ending_time) { 1.week.after(Time.utc(2023)) }

  let(:project) { project1 }
  let(:status_groups) { [:all] }
  let(:from_time) { starting_time }
  let(:to_time) { ending_time }

  let(:service) do
    described_class.new(
      current_user: current_user,
      project: project,
      from_time: from_time,
      to_time: to_time,
      status_groups: status_groups)
  end

  let(:pipelines) do
    [
      create_pipeline(project1, :running, 35.minutes.before(ending_time), 30.minutes),
      create_pipeline(project1, :success, 1.day.before(ending_time), 30.minutes),
      create_pipeline(project1, :canceled, 1.hour.before(ending_time), 1.minute),
      create_pipeline(project1, :failed, 5.days.before(ending_time), 2.hours),
      create_pipeline(project1, :failed, 1.week.before(ending_time), 45.minutes),
      create_pipeline(project1, :skipped, 5.days.before(ending_time), 1.second),
      create_pipeline(project1, :skipped, 1.second.before(starting_time), 45.minutes),
      create_pipeline(project1, :success, ending_time, 30.minutes)
    ]
  end

  subject(:result) { service.execute }

  before do
    insert_ci_pipelines_to_click_house(pipelines)
  end

  context 'when ClickHouse database is not configured' do
    before do
      allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(false)
    end

    it 'returns error' do
      expect(result.error?).to eq(true)
      expect(result.errors).to contain_exactly('ClickHouse database is not configured')
    end
  end

  shared_examples 'returns Not allowed error' do
    it 'returns error' do
      expect(result.error?).to eq(true)
      expect(result.errors).to contain_exactly('Not allowed')
    end
  end

  shared_examples 'a service returning aggregate analytics' do
    using RSpec::Parameterized::TableSyntax

    where(:status_groups, :expected_aggregate) do
      %i[all]           | { all: 6 }
      %i[all success]   | { all: 6, success: 1 }
      %i[success other] | { success: 1, other: 2 }
      %i[failed]        | { failed: 2 }
    end

    with_them do
      it 'returns aggregate analytics' do
        expect(result.success?).to eq(true)
        expect(result.errors).to eq([])
        expect(result.payload[:aggregate]).to eq(expected_aggregate)
      end
    end

    context 'when dates are not specified' do
      let(:from_time) { nil }
      let(:to_time) { nil }

      context 'and there are pipelines in the last week', time_travel_to: '2023-01-08' do
        it 'returns aggregate analytics from last week' do
          expect(result.errors).to eq([])
          expect(result.success?).to eq(true)
          expect(result.payload[:aggregate]).to eq({ all: 6 })
        end
      end

      context 'and there are no pipelines in the last week', time_travel_to: '2023-01-15 00:00:01' do
        it 'returns empty aggregate analytics' do
          expect(result.errors).to eq([])
          expect(result.success?).to eq(true)
          expect(result.payload[:aggregate]).to eq({ all: 0 })
        end
      end
    end

    context 'when requesting statistics starting one second before beginning of week' do
      let(:from_time) { 1.second.before(starting_time) }

      it 'does not include job starting 1 second before start of week' do
        expect(result.errors).to eq([])
        expect(result.success?).to eq(true)
        expect(result.payload[:aggregate]).to eq({ all: 6 })
      end
    end

    context 'when requesting statistics starting one hour before beginning of week' do
      let(:from_time) { 1.hour.before(starting_time) }

      it 'includes job starting 1 second before start of week' do
        expect(result.errors).to eq([])
        expect(result.success?).to eq(true)
        expect(result.payload[:aggregate]).to eq({ all: 7 })
      end
    end

    context 'when requesting hourly statistics that span more than one week' do
      let(:from_time) { (1.hour + 1.second).before(starting_time) }

      it 'returns an error' do
        expect(result.errors).to contain_exactly(
          "Maximum of #{described_class::TIME_BUCKETS_LIMIT} 1-hour intervals can be requested")
        expect(result.error?).to eq(true)
      end
    end

    context 'when a different project is specified' do
      let(:project) { project2 }
      let(:status_groups) { %i[all success failed] }

      before do
        insert_ci_pipelines_to_click_house([
          create_pipeline(project2, :failed, 1.week.before(ending_time), 45.minutes)
        ])
      end

      it 'returns aggregate analytics for specified project only' do
        expect(result.success?).to eq(true)
        expect(result.errors).to eq([])
        expect(result.payload[:aggregate]).to eq({ all: 1, success: 0, failed: 1 })
      end
    end
  end

  it_behaves_like 'a service returning aggregate analytics'

  context 'when user is nil' do
    let(:current_user) { nil }

    include_examples 'returns Not allowed error'
  end

  context 'when project has analytics disabled' do
    let_it_be(:project) { create(:project, :analytics_disabled) }

    include_examples 'returns Not allowed error'
  end

  context 'when project is not specified' do
    let(:project) { nil }

    it 'returns error' do
      expect(result.error?).to eq(true)
      expect(result.errors).to contain_exactly('Project must be specified')
    end
  end

  context 'when user is an admin' do
    let(:current_user) { create(:admin) }

    it_behaves_like 'a service returning aggregate analytics'
  end

  context 'when user is a guest' do
    let_it_be(:current_user) { create(:user, guest_of: project1) }

    include_examples 'returns Not allowed error'
  end

  def create_pipeline(project, status, started_at, duration)
    build_stubbed(:ci_pipeline, status,
      project: project,
      created_at: 1.second.before(started_at), started_at: started_at, finished_at: duration.after(started_at),
      duration: duration)
  end
end
