# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Charts, :freeze_time, feature_category: :fleet_visibility do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }

  before_all do
    create_pipeline(:success, 11.months.ago, 2.hours)
    create_pipeline(:failed, 10.months.ago, 1.hour)
    create_pipeline(:canceled, 3.weeks.ago, 2.hours)
    create_pipeline(:success, 6.days.ago, 1.hour)
  end

  describe 'yearchart' do
    let(:selected_statuses) { [] }
    let(:chart) { Gitlab::Ci::Charts::YearChart.new(project, selected_statuses) }

    it 'goes until the end of the current month (including the whole last day of the month)' do
      expect(chart.to).to eq(Date.today.end_of_month.end_of_day)
    end

    it 'starts at the beginning of the current year' do
      expect(chart.from).to eq(chart.to.years_ago(1).beginning_of_month.beginning_of_day)
    end

    it 'uses %B %Y as labels format' do
      expect(chart.labels).to include(chart.from.strftime('%B %Y'))
    end

    describe '#totals' do
      subject(:totals) { chart.totals(status: status) }

      where(:status, :selected_statuses, :expected_sum) do
        :all     | []                 | 4 # computed even if field is not selected
        :success | %i[failed]         | 0
        :success | %i[success failed] | 2
        :failed  | %i[success failed] | 1
        :other   | %i[other]          | 1
      end

      with_them do
        it 'returns count of pipelines run each day in the current year' do
          expect(totals&.sum).to eq(expected_sum)
        end
      end
    end
  end

  describe 'monthchart' do
    let(:selected_statuses) { [] }
    let(:chart) { Gitlab::Ci::Charts::MonthChart.new(project, selected_statuses) }

    it 'includes the whole current day' do
      expect(chart.to).to eq(Date.today.end_of_day)
    end

    it 'starts one month ago' do
      expect(chart.from).to eq(1.month.ago.beginning_of_day)
    end

    it 'uses %d %B as labels format' do
      expect(chart.labels).to include(chart.from.strftime('%d %B'))
    end

    describe '#totals' do
      subject(:totals) { chart.totals(status: status) }

      where(:status, :selected_statuses, :expected_sum) do
        :all     | []                 | 2 # computed even if field is not selected
        :success | %i[failed]         | 0
        :success | %i[success failed] | 1
        :failed  | %i[success failed] | 0
        :other   | %i[other]          | 1
      end

      with_them do
        it 'returns count of pipelines run each day in the current month' do
          expect(totals&.sum).to eq(expected_sum)
        end
      end
    end
  end

  describe 'weekchart' do
    let(:selected_statuses) { [] }
    let(:chart) { Gitlab::Ci::Charts::WeekChart.new(project, selected_statuses) }

    it 'includes the whole current day' do
      expect(chart.to).to eq(Date.today.end_of_day)
    end

    it 'starts one week ago' do
      expect(chart.from).to eq(1.week.ago.beginning_of_day)
    end

    it 'uses %d %B as labels format' do
      expect(chart.labels).to include(chart.from.strftime('%d %B'))
    end

    describe '#totals' do
      subject(:totals) { chart.totals(status: status) }

      where(:status, :selected_statuses, :expected_sum) do
        :all     | []                 | 1 # computed even if field is not selected
        :success | %i[failed]         | 0
        :success | %i[success failed] | 1
        :failed  | %i[success failed] | 0
        :other   | %i[other]          | 0
      end

      with_them do
        it 'returns count of pipelines run each day in the current week' do
          expect(totals&.sum).to eq(expected_sum)
        end
      end
    end
  end

  context 'weekchart_utc' do
    let_it_be(:today) { Date.today }
    let_it_be(:end_of_today) do
      Time.use_zone(Time.find_zone('UTC')) { today.end_of_day }
    end

    let(:chart) { Gitlab::Ci::Charts::WeekChart.new(project) }

    before_all do
      # The created_at time used by the following execution
      # can end up being after the creation of the 'today' time
      # objects created above, and cause the queried counts to
      # go to zero when the test executes close to midnight on the
      # CI system, so we explicitly set it to a day earlier
      create(:ci_pipeline, project: project, duration: 120, created_at: 1.day.before(today))
    end

    before do
      allow(Date).to receive(:today).and_return(today)
      allow(today).to receive(:end_of_day).and_return(end_of_today)
    end

    it 'uses a utc time zone for range times' do
      expect(chart.to.zone).to eq(end_of_today.zone)
      expect(chart.from.zone).to eq(end_of_today.zone)
    end

    it 'returns count of pipelines run each day in the current week' do
      expect(chart.totals.sum).to eq(2)
    end
  end

  context 'weekchart_non_utc' do
    let_it_be(:today) { Date.today }
    let_it_be(:end_of_today) do
      Time.use_zone(Time.find_zone('Asia/Dubai')) { today.end_of_day }
    end

    let(:chart) { Gitlab::Ci::Charts::WeekChart.new(project) }

    subject { chart.totals }

    before_all do
      # The DB uses UTC always, so our use of a Time Zone in the application
      # can cause the creation date of the pipeline to go unmatched depending
      # on the offset. We can work around this by requesting the pipeline be
      # created a with the `created_at` field set to a day ago in the same week.
      create(:ci_pipeline, project: project, duration: 120, created_at: 1.day.before(today))
    end

    before do
      allow(Date).to receive(:today).and_return(today)
      allow(today).to receive(:end_of_day).and_return(end_of_today)
    end

    it 'uses a non-utc time zone for range times' do
      expect(chart.to.zone).to eq(end_of_today.zone)
      expect(chart.from.zone).to eq(end_of_today.zone)
    end

    it 'returns count of pipelines run each day in the current week' do
      expect(chart.totals.sum).to eq(2)
    end
  end

  describe '#pipeline_times' do
    let(:chart) { Gitlab::Ci::Charts::PipelineTime.new(project) }

    subject { chart.pipeline_times }

    it 'returns pipeline times in minutes' do
      is_expected.to contain_exactly(60, 60, 120, 120)
    end

    context 'when a pipeline has nil duration' do
      before_all do
        create(:ci_pipeline, project: project, duration: nil)
      end

      it 'handles nil pipeline times' do
        is_expected.to contain_exactly(60, 60, 120, 120, 0)
      end
    end
  end

  def create_pipeline(status, started_at, duration)
    pipeline = create(:ci_pipeline, status, project: project,
      created_at: 1.second.before(started_at), started_at: started_at)

    status = :success if status == :manual
    create(:ci_build, status, pipeline: pipeline,
      created_at: pipeline.created_at,
      started_at: pipeline.started_at,
      finished_at: pipeline.started_at + duration)

    pipeline.update_duration
    pipeline.save!
  end
end
