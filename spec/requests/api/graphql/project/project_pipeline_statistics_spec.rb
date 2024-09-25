# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'rendering project pipeline statistics', :aggregate_failures, :click_house, feature_category: :fleet_visibility do
  include ClickHouseHelpers
  include GraphqlHelpers

  let_it_be(:project) { create(:project).tap(&:reload) } # NOTE: reload is necessary to compute traversal_ids
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }

  let(:from_time) { nil }
  let(:to_time) { nil }
  let(:pipelines) do
    current_time = Time.utc(2024, 5, 11)

    [
      create_pipeline(:running, 35.minutes.before(current_time), 30.minutes),
      create_pipeline(:success, 1.day.before(current_time), 30.minutes),
      create_pipeline(:failed, 5.days.before(current_time), 2.hours),
      create_pipeline(:failed, 1.week.before(current_time), 45.minutes),
      create_pipeline(:skipped, 7.months.before(current_time), 45.minutes)
    ]
  end

  let(:user) { reporter }

  let(:period_fields) do
    <<~QUERY
      label
      all: count
      success: count(status: SUCCESS)
      failed: count(status: FAILED)
      other: count(status: OTHER)
    QUERY
  end

  let(:query) do
    graphql_query_for(
      :project, { full_path: project.full_path },
      query_graphql_field(
        :pipeline_analytics, { from_time: from_time, to_time: to_time }.compact,
        fields)
    )
  end

  subject(:perform_request) do
    post_graphql(query, current_user: user)
  end

  before do
    insert_ci_pipelines_to_click_house(pipelines)
  end

  it_behaves_like 'a working graphql query' do
    let(:fields) do
      <<~QUERY
        aggregate { #{period_fields} }

        weekPipelinesTotals
        weekPipelinesLabels
        monthPipelinesLabels
        monthPipelinesTotals
        yearPipelinesLabels
        yearPipelinesTotals
      QUERY
    end

    before do
      perform_request
    end
  end

  describe 'aggregate' do
    subject(:aggregate) do
      perform_request

      graphql_data_at(:project, :pipelineAnalytics, :aggregate)
    end

    let(:fields) do
      <<~QUERY
        aggregate { #{period_fields} }
      QUERY
    end

    it "contains expected data for the last week" do
      expect(aggregate).to eq({
        'label' => nil,
        'all' => '0',
        'success' => '0',
        'failed' => '0',
        'other' => '0'
      })
    end

    context 'when there are pipelines in last week', time_travel_to: Time.utc(2024, 5, 11) do
      it "contains expected data for the last week" do
        expect(aggregate).to eq({
          'label' => nil,
          'all' => '4',
          'success' => '1',
          'failed' => '2',
          'other' => '0'
        })
      end
    end

    context 'when time window is specified' do
      let(:from_time) { '2024-05-10T00:00:00+00:00' }
      let(:to_time) { '2024-05-11T00:00:00+00:00' }

      it "contains expected data for the period" do
        expect(aggregate).to eq({
          'label' => nil,
          'all' => '2',
          'success' => '1',
          'failed' => '0',
          'other' => '0'
        })
      end
    end
  end

  describe 'week statistics', time_travel_to: Time.utc(2024, 5, 11) do
    let(:fields) do
      <<~QUERY
        aggregate { #{period_fields} }

        weekPipelinesLabels
        weekPipelinesTotals
        weekPipelinesSuccessful
      QUERY
    end

    it 'contains only requested fields' do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics).keys).to contain_exactly(
        'aggregate', 'weekPipelinesLabels', 'weekPipelinesTotals', 'weekPipelinesSuccessful'
      )
    end

    it 'executes exactly 2 queries on ci_pipelines', :use_sql_query_cache do
      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { perform_request }

      expect(recorder.log).to include(a_string_matching(/FROM "ci_pipelines"/)).twice
    end

    it "contains expected data for the week's pipelines" do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesLabels)).to eq(
        ['04 May', '05 May', '06 May', '07 May', '08 May', '09 May', '10 May', '11 May'])
      expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesTotals)).to eq([0, 1, 0, 0, 0, 1, 1, 0])
      expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesSuccessful)).to eq([0, 0, 0, 0, 0, 1, 0, 0])
    end

    it "contains two arrays of 8 elements each for the week pipelines" do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesTotals).length).to eq(8)
      expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesLabels).length).to eq(8)
    end

    context 'when only weekPipelines* fields are requested' do
      let(:fields) do
        <<~QUERY
          weekPipelinesTotals
          weekPipelinesLabels
          weekPipelinesSuccessful
        QUERY
      end

      it "contains three arrays of 8 elements each for the week pipelines" do
        perform_request

        expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesTotals).length).to eq(8)
        expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesLabels).length).to eq(8)
        expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesSuccessful).length).to eq(8)
      end
    end

    context 'when user has no permissions' do
      let(:user) { guest }

      it 'returns nil in pipelineAnalytics' do
        perform_request

        expect(graphql_data_at(:project, :pipelineAnalytics)).to be_nil
      end
    end
  end

  describe 'monthly statistics' do
    let(:fields) do
      <<~QUERY
        aggregate { #{period_fields} }

        monthPipelinesLabels
        monthPipelinesTotals
        monthPipelinesSuccessful
      QUERY
    end

    it 'contains only requested fields' do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics).keys).to contain_exactly(
        'aggregate', 'monthPipelinesLabels', 'monthPipelinesTotals', 'monthPipelinesSuccessful'
      )
    end

    it 'executes exactly 2 queries on ci_pipelines', :use_sql_query_cache do
      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { perform_request }

      expect(recorder.log).to include(a_string_matching(/FROM "ci_pipelines"/)).twice
    end

    shared_examples 'monthly statistics' do |timestamp, expected_quantity|
      around do |example|
        travel_to(timestamp) do
          example.run
        end
      end

      it 'executes exactly 2 queries on ci_pipelines', :use_sql_query_cache do
        recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { perform_request }

        expect(recorder.log).to include(a_string_matching(/FROM "ci_pipelines"/)).twice
      end

      it "contains three arrays of #{expected_quantity} elements each for the month pipelines" do
        perform_request

        expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesLabels).length).to eq(expected_quantity)
        expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesTotals).length).to eq(expected_quantity)
        expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesSuccessful).length).to eq(expected_quantity)
      end

      context 'when only monthPipelines* fields are requested' do
        let(:fields) do
          <<~QUERY
            monthPipelinesTotals
            monthPipelinesLabels
            monthPipelinesSuccessful
          QUERY
        end

        it "contains three arrays of #{expected_quantity} elements each for the month pipelines" do
          perform_request

          expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesTotals).length).to eq(expected_quantity)
          expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesLabels).length).to eq(expected_quantity)
          expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesSuccessful).length)
            .to eq(expected_quantity)
        end
      end
    end

    it "contains expected data for the month's pipelines", time_travel_to: Time.utc(2024, 5, 11) do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesLabels)).to eq(
        [
          '11 April', '12 April', '13 April', '14 April', '15 April', '16 April', '17 April', '18 April',
          '19 April', '20 April', '21 April', '22 April', '23 April', '24 April', '25 April', '26 April',
          '27 April', '28 April', '29 April', '30 April', '01 May', '02 May', '03 May', '04 May', '05 May',
          '06 May', '07 May', '08 May', '09 May', '10 May', '11 May'
        ]
      )
      expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesTotals)).to eq(
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0]
      )
      expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesSuccessful)).to eq(
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
      )
    end

    it_behaves_like 'monthly statistics', Time.zone.local(2019, 2, 28), 32
    it_behaves_like 'monthly statistics', Time.zone.local(2020, 12, 30), 31
    it_behaves_like 'monthly statistics', Time.zone.local(2020, 12, 31), 32

    context 'when user has no permissions' do
      let(:user) { guest }

      it 'returns nil in pipelineAnalytics' do
        perform_request

        expect(graphql_data_at(:project, :pipelineAnalytics)).to be_nil
      end
    end
  end

  describe 'year statistics', time_travel_to: Time.utc(2024, 5, 11) do
    let(:fields) do
      <<~QUERY
        aggregate { #{period_fields} }

        yearPipelinesLabels
        yearPipelinesTotals
        yearPipelinesSuccessful
      QUERY
    end

    it 'contains only requested fields' do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics).keys).to contain_exactly(
        'aggregate', 'yearPipelinesLabels', 'yearPipelinesTotals', 'yearPipelinesSuccessful'
      )
    end

    it 'executes exactly 2 queries on ci_pipelines', :use_sql_query_cache do
      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { perform_request }

      expect(recorder.log).to include(a_string_matching(/FROM "ci_pipelines"/)).twice
    end

    it "contains expected data for the year's pipelines" do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesLabels)).to eq(
        ['May 2023', 'June 2023', 'July 2023', 'August 2023', 'September 2023', 'October 2023',
          'November 2023', 'December 2023', 'January 2024', 'February 2024', 'March 2024', 'April 2024',
          'May 2024'])
      expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesTotals)).to eq(
        [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 4])
      expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesSuccessful)).to eq(
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])
    end

    it "contains two arrays of 13 elements each for the year pipelines" do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesTotals).length).to eq(13)
      expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesLabels).length).to eq(13)
    end

    context 'when only yearPipelines* fields are requested' do
      let(:fields) do
        <<~QUERY
          yearPipelinesTotals
          yearPipelinesLabels
          yearPipelinesSuccessful
        QUERY
      end

      it "contains three arrays of 13 elements each for the year pipelines" do
        perform_request

        expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesTotals).length).to eq(13)
        expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesLabels).length).to eq(13)
        expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesSuccessful).length).to eq(13)
      end
    end

    context 'when user has no permissions' do
      let(:user) { guest }

      it 'returns nil in pipelineAnalytics' do
        perform_request

        expect(graphql_data_at(:project, :pipelineAnalytics)).to be_nil
      end
    end
  end

  def create_pipeline(status, started_at, duration)
    # NOTE: This can be switched to build_stubbed once the legacy fields are removed and we rely solely
    # on CollectPipelineAnalyticsService
    pipeline = create(:ci_pipeline, status, project: project,
      created_at: 1.second.before(started_at), started_at: started_at)

    status = :success if status == :manual
    create(:ci_build, status, pipeline: pipeline,
      created_at: pipeline.created_at,
      started_at: pipeline.started_at,
      finished_at: duration.after(pipeline.started_at))

    pipeline.update_duration
    pipeline.tap(&:save!)
  end
end
