# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::CollectAggregatePipelineAnalyticsService, :click_house, :enable_admin_mode,
  feature_category: :fleet_visibility do
  include ClickHouseHelpers

  include_context 'with pipelines executed on different projects'

  let(:project) { project1 }
  let(:status_groups) { [:any] }
  let(:duration_percentiles) { [] }
  let(:from_time) { starting_time }
  let(:to_time) { ending_time }

  let(:service) do
    described_class.new(
      current_user: current_user,
      project: project,
      from_time: from_time,
      to_time: to_time,
      status_groups: status_groups,
      duration_percentiles: duration_percentiles)
  end

  subject(:result) { service.execute }

  before do
    insert_ci_pipelines_to_click_house(pipelines)
  end

  shared_examples 'a service returning aggregate analytics' do
    using RSpec::Parameterized::TableSyntax

    where(:status_groups, :duration_percentiles, :expected_aggregate) do
      %i[any]           | []       | { count: { any: 8 } }
      %i[any]           | [50, 75] | { count: { any: 8 }, duration_statistics: { p50: 30.minutes, p75: 63.75.minutes } }
      %i[any success]   | []       | { count: { any: 8, success: 2 } }
      %i[success other] | []       | { count: { success: 2, other: 3 } }
      %i[failed]        | [50, 75] |
        { count: { failed: 2 }, duration_statistics: { p50: 30.minutes, p75: 63.75.minutes } }
    end

    with_them do
      it 'returns aggregate analytics' do
        expect(result).to be_success
        expect(result.errors).to eq([])
        expect(result.payload[:aggregate]).to eq(expected_aggregate)
      end
    end

    context 'when dates are not specified' do
      let(:from_time) { nil }
      let(:to_time) { nil }
      let(:duration_percentiles) { [50, 99] }

      context 'and there are pipelines in the last week', time_travel_to: '2023-01-08' do
        it 'returns aggregate analytics from last week' do
          expect(result).to be_success
          expect(result.errors).to eq([])
          expect(result.payload[:aggregate]).to eq(
            count: { any: 8 }, duration_statistics: { p50: 30.minutes, p99: 4026.minutes }
          )
        end
      end

      context 'and there are no pipelines in the last week', time_travel_to: '2023-01-15 00:00:01' do
        it 'returns empty aggregate analytics' do
          expect(result).to be_success
          expect(result.errors).to eq([])
          expect(result.payload[:aggregate]).to eq(count: { any: 0 }, duration_statistics: { p50: 0, p99: 0 })
        end
      end
    end

    context 'when requesting statistics starting one second before beginning of week' do
      let(:from_time) { 1.second.before(starting_time) }
      let(:to_time) { 1.second.before(ending_time) }

      it 'does not include job starting 1 second before start of week' do
        expect(result).to be_success
        expect(result.errors).to eq([])
        expect(result.payload[:aggregate]).to eq(count: { any: 8 })
      end
    end

    context 'when requesting statistics starting one hour before beginning of week' do
      let(:from_time) { 1.hour.before(starting_time) }
      let(:to_time) { 1.second.before(ending_time) }

      it 'includes job starting 1 second before start of week' do
        expect(result).to be_success
        expect(result.errors).to eq([])
        expect(result.payload[:aggregate]).to eq(count: { any: 9 })
      end
    end

    context 'when requesting statistics that span more than one year' do
      let(:from_time) { (366.days + 1.second).before(starting_time) }

      it 'returns an error' do
        expect(result.errors).to contain_exactly("Maximum of 366 days can be requested")
        expect(result.error?).to be true
      end
    end

    context 'when a different project is specified' do
      let(:project) { project2 }
      let(:status_groups) { %i[any success failed] }

      before do
        insert_ci_pipelines_to_click_house([
          create_pipeline(project2, :failed, 1.week.before(ending_time), 45.minutes)
        ])
      end

      it 'returns aggregate analytics for specified project only' do
        expect(result).to be_success
        expect(result.errors).to eq([])
        expect(result.payload[:aggregate]).to eq(count: { any: 1, success: 0, failed: 1 })
      end
    end
  end

  it_behaves_like 'a pipeline analytics service'
  it_behaves_like 'a service returning aggregate analytics'

  context 'when user is an admin' do
    let_it_be(:current_user) { create(:admin) }

    it_behaves_like 'a service returning aggregate analytics'
  end
end
