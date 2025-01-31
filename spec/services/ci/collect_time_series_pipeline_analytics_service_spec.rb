# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::CollectTimeSeriesPipelineAnalyticsService, :click_house, :enable_admin_mode,
  feature_category: :fleet_visibility do
  include ClickHouseHelpers

  include_context 'with pipelines executed on different projects'

  let(:project) { project1 }
  let(:status_groups) { [:any] }
  let(:duration_percentiles) { [] }
  let(:duration_percentile_symbols) { duration_percentiles.map { |p| :"p#{p}" } }
  let(:from_time) { starting_time }
  let(:to_time) { ending_time }
  let(:expected_1st_day) { (from_time || 1.week.ago.utc).beginning_of_day }
  let(:time_series_period) { :day }
  let(:time_series_filters) do
    { count: status_groups, duration_statistics: duration_percentile_symbols }
  end

  let(:service) do
    described_class.new(
      current_user: current_user,
      project: project,
      from_time: from_time,
      to_time: to_time,
      time_series_period: time_series_period,
      status_groups: status_groups,
      duration_percentiles: duration_percentiles)
  end

  subject(:result) { service.execute }

  before do
    insert_ci_pipelines_to_click_house(pipelines)
  end

  shared_examples 'a service reporting metrics for time series analytics' do
    it_behaves_like 'internal event tracking' do
      let(:event) { 'collect_time_series_pipeline_analytics' }
      let(:category) { described_class.name }
      let(:user) { current_user }
      let(:additional_properties) do
        { property: time_series_period.to_s }
      end
    end
  end

  shared_examples 'a service returning time series analytics' do
    using RSpec::Parameterized::TableSyntax

    let(:no_pipeline_statistics) do
      {
        count: { success: 0, failed: 0, other: 0, any: 0 },
        duration_statistics: duration_percentile_symbols.index_with(0.seconds)
      }
    end

    let(:expected_full_time_series) do
      [
        {
          label: Time.utc(2023, 1, 1),
          count: { success: 0, failed: 1, other: 0, any: 1 },
          duration_statistics: { p50: 45.minutes, p95: 45.minutes, p99: 45.minutes }
        },
        { label: Time.utc(2023, 1, 2), **no_pipeline_statistics },
        {
          label: Time.utc(2023, 1, 3),
          count: { success: 0, failed: 1, other: 2, any: 3 },
          duration_statistics: { p50: 60.seconds, p95: 6486.seconds, p99: 7057.2.seconds }
        },
        { label: Time.utc(2023, 1, 4), **no_pipeline_statistics },
        { label: Time.utc(2023, 1, 5), **no_pipeline_statistics },
        {
          label: Time.utc(2023, 1, 6),
          count: { success: 1, failed: 0, other: 0, any: 1 },
          duration_statistics: { p50: 3.days, p95: 3.days, p99: 3.days }
        },
        {
          label: Time.utc(2023, 1, 7),
          count: { success: 1, failed: 0, other: 1, any: 3 },
          duration_statistics: { p50: 30.minutes, p95: 30.minutes, p99: 30.minutes }
        }
      ]
    end

    let(:expected_time_series) { filter_time_series(expected_full_time_series, **time_series_filters) }

    where(:status_groups, :duration_percentiles) do
      %i[any]           | []
      %i[any]           | [50, 95]
      %i[success other] | []
      %i[failed other]  | [50, 99]
      %i[failed]        | [50, 95]
    end

    with_them do
      it 'returns time series analytics' do
        expect(result).to be_success
        expect(result.errors).to eq([])
        expect(result.payload[:time_series]).to eq(expected_time_series)
      end
    end

    describe 'period' do
      let(:duration_percentiles) { [50, 95] }

      context 'with unspecified period' do
        let(:time_series_period) { nil }

        it 'returns error' do
          expect(result).to be_error
          expect(result.message).to eq 'invalid time series period'
        end
      end

      context 'with invalid period' do
        let(:time_series_period) { :unknown }

        it 'returns error' do
          expect(result).to be_error
          expect(result.message).to eq 'invalid time series period'
        end
      end

      context 'with weekly period' do
        let(:time_series_period) { :week }

        it_behaves_like 'a service reporting metrics for time series analytics'

        it 'returns weekly time series analytics' do
          expect(result).to be_success
          expect(result.errors).to eq([])
          expect(result.payload[:time_series]).to eq([
            {
              label: Time.utc(2022, 12, 26), count: { any: 1 },
              duration_statistics: { p50: 45.minutes, p95: 45.minutes }
            },
            {
              label: Time.utc(2023, 1, 2), count: { any: 7 }, duration_statistics: { p50: 30.minutes, p95: 51.hours }
            }
          ])
        end
      end

      context 'with monthly period' do
        let(:time_series_period) { :month }

        it_behaves_like 'a service reporting metrics for time series analytics'

        it 'returns monthly time series analytics' do
          expect(result).to be_success
          expect(result.errors).to eq([])
          expect(result.payload[:time_series]).to eq([
            {
              label: Time.utc(2023, 1, 1), count: { any: 8 }, duration_statistics: { p50: 30.minutes, p95: 47.5.hours }
            }
          ])
        end
      end
    end

    context 'when dates are not specified' do
      let(:from_time) { nil }
      let(:to_time) { nil }
      let(:duration_percentiles) { [50, 99] }

      it_behaves_like 'a service reporting metrics for time series analytics'

      context 'and there are pipelines in the last week', time_travel_to: '2023-01-08' do
        it 'returns time series analytics from last week' do
          expect(result).to be_success
          expect(result.errors).to eq([])
          expect(result.payload[:time_series]).to eq(expected_time_series)
        end
      end

      context 'and there are no pipelines in the last week', time_travel_to: '2023-01-15 00:00:01' do
        it 'returns time series analytics with zero duration' do
          expect(result).to be_success
          expect(result.errors).to eq([])
          expect(result.payload[:time_series]).to eq(no_pipeline_statistics_for_day_range(8..15))
        end
      end
    end

    context 'when requesting statistics starting one second before beginning of week' do
      let(:from_time) { 1.second.before(starting_time) }
      let(:to_time) { 1.second.before(ending_time) }

      it 'does not include job starting 1 second before start of week' do
        expect(result).to be_success
        expect(result.errors).to eq([])
        expect(result.payload[:time_series]).to eq(filter_time_series([
          { label: Time.utc(2022, 12, 31), **no_pipeline_statistics },
          *expected_time_series
        ], **time_series_filters))
      end
    end

    context 'when requesting statistics starting one hour before beginning of week' do
      let(:from_time) { 1.hour.before(starting_time) }
      let(:to_time) { 1.second.before(ending_time) }

      it 'includes job starting 1 second before start of week' do
        expect(result).to be_success
        expect(result.errors).to eq([])
        expect(result.payload[:time_series]).to eq([
          { label: Time.utc(2022, 12, 31), count: { any: 1 } },
          *expected_time_series
        ])
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
          create_pipeline(project2, :failed, 1.week.before(ending_time), 90.minutes),
          create_pipeline(project2, :success, 1.week.before(ending_time), 2.minutes),
          create_pipeline(project2, :success, 1.week.before(ending_time), 29.minutes)
        ])
      end

      it 'returns time series analytics for specified project only' do
        expect(result).to be_success
        expect(result.errors).to eq([])
        expect(result.payload[:time_series]).to eq([
          { label: Time.utc(2023, 1, 1), count: { any: 3, failed: 1, success: 2 } },
          *no_pipeline_statistics_for_day_range(2..7)
        ])
      end
    end

    private

    def no_pipeline_statistics_for_day_range(range)
      time_series = range.map do |day|
        { label: Time.utc(2023, 1, day), **no_pipeline_statistics }
      end

      filter_time_series(time_series, **time_series_filters)
    end

    def filter_time_series(time_series, **fields)
      time_series.map do |entry|
        entry
          .slice(:label, *fields.keys)
          .to_h do |entry_key, entry_value|
            [
              entry_key,
              entry_value.is_a?(Hash) ? entry_value.slice(*fields[entry_key]).presence : entry_value
            ]
          end.compact
      end
    end
  end

  it_behaves_like 'a pipeline analytics service'
  it_behaves_like 'a service returning time series analytics'

  context 'when user is an admin' do
    let_it_be(:current_user) { create(:admin) }

    it_behaves_like 'a service returning time series analytics'
  end
end
