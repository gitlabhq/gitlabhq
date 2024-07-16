# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'rendering project pipeline statistics', :aggregate_failures, feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:guest) { create(:user, guest_of: project) }

  let(:user) { reporter }

  let(:period_fields) do
    <<~QUERY
      labels
      all: totals
      success: totals(status: SUCCESS)
      failed: totals(status: FAILED)
      other: totals(status: OTHER)
    QUERY
  end

  let(:query) do
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_graphql_field(:pipeline_analytics, {}, fields)
    )
  end

  subject(:perform_request) do
    post_graphql(query, current_user: user)
  end

  before_all do
    travel_to(Time.utc(2024, 5, 11)) do
      create_pipeline(:running, 35.minutes.ago, 30.minutes)
      create_pipeline(:success, 1.day.ago, 30.minutes)
      create_pipeline(:failed, 5.days.ago, 2.hours)
      create_pipeline(:failed, 1.week.ago, 45.minutes)
      create_pipeline(:skipped, 7.months.ago, 45.minutes)
    end
  end

  it_behaves_like 'a working graphql query' do
    let(:fields) do
      <<~QUERY
        weekPipelines { #{period_fields} }
        monthPipelines { #{period_fields} }
        yearPipelines { #{period_fields} }

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

  describe 'week statistics', time_travel_to: Time.utc(2024, 5, 11) do
    subject(:stats) do
      perform_request

      graphql_data_at(:project, :pipelineAnalytics, :weekPipelines)
    end

    let(:fields) do
      <<~QUERY
        weekPipelines { #{period_fields} }

        weekPipelinesTotals
        weekPipelinesLabels
      QUERY
    end

    it 'contains only requested fields' do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics).keys).to contain_exactly(
        'weekPipelines', 'weekPipelinesTotals', 'weekPipelinesLabels'
      )
    end

    it 'executes exactly 2 queries on ci_pipelines', :use_sql_query_cache do
      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { perform_request }

      expect(recorder.log).to include(a_string_matching(/FROM "ci_pipelines"/)).twice
    end

    it "contains expected data for the week's pipelines" do
      expect(stats).to match(a_hash_including(
        'labels' => ['04 May', '05 May', '06 May', '07 May', '08 May', '09 May', '10 May', '11 May'],
        'all' => [0, 1, 0, 0, 0, 1, 1, 0],
        'success' => [0, 0, 0, 0, 0, 1, 0, 0],
        'failed' => [0, 1, 0, 0, 0, 0, 0, 0],
        'other' => [0, 0, 0, 0, 0, 0, 1, 0]
      ))
    end

    it "contains two arrays of 8 elements each for the week pipelines" do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesTotals).length).to eq(8)
      expect(graphql_data_at(:project, :pipelineAnalytics, :weekPipelinesLabels).length).to eq(8)
    end

    context 'when user has no permissions' do
      let(:user) { guest }

      it { expect(stats).to be_nil }
    end
  end

  describe 'monthly statistics' do
    subject(:stats) do
      perform_request

      graphql_data_at(:project, :pipelineAnalytics, :monthPipelines)
    end

    let(:fields) do
      <<~QUERY
        monthPipelines { #{period_fields} }

        monthPipelinesLabels
        monthPipelinesTotals
      QUERY
    end

    it 'contains only requested fields' do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics).keys).to contain_exactly(
        'monthPipelines', 'monthPipelinesLabels', 'monthPipelinesTotals'
      )
    end

    it 'executes exactly 2 queries on ci_pipelines', :use_sql_query_cache do
      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { perform_request }

      expect(recorder.log).to include(a_string_matching(/FROM "ci_pipelines"/)).twice
    end

    it "contains expected data for the month's pipelines", time_travel_to: Time.utc(2024, 5, 11) do
      expect(stats).to match(a_hash_including(
        'labels' => ['11 April', '12 April', '13 April', '14 April', '15 April', '16 April', '17 April', '18 April',
          '19 April', '20 April', '21 April', '22 April', '23 April', '24 April', '25 April', '26 April',
          '27 April', '28 April', '29 April', '30 April', '01 May', '02 May', '03 May', '04 May', '05 May',
          '06 May', '07 May', '08 May', '09 May', '10 May', '11 May'],
        'all' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0],
        'success' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
        'failed' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0],
        'other' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]
      ))
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

      it "contains #{expected_quantity} elements for each hash" do
        expect(stats['labels'].length).to eq(expected_quantity)
        expect(stats['all'].length).to eq(expected_quantity)
        expect(stats['success'].length).to eq(expected_quantity)
        expect(stats['failed'].length).to eq(expected_quantity)
        expect(stats['other'].length).to eq(expected_quantity)
      end

      it "contains two arrays of #{expected_quantity} elements each for the month pipelines" do
        perform_request

        expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesTotals).length).to eq(expected_quantity)
        expect(graphql_data_at(:project, :pipelineAnalytics, :monthPipelinesLabels).length).to eq(expected_quantity)
      end
    end

    it_behaves_like 'monthly statistics', Time.zone.local(2019, 2, 28), 32
    it_behaves_like 'monthly statistics', Time.zone.local(2020, 12, 30), 31
    it_behaves_like 'monthly statistics', Time.zone.local(2020, 12, 31), 32

    context 'when user has no permissions' do
      let(:user) { guest }

      it { expect(stats).to be_nil }
    end
  end

  describe 'year statistics', time_travel_to: Time.utc(2024, 5, 11) do
    subject(:stats) do
      perform_request

      graphql_data_at(:project, :pipelineAnalytics, :yearPipelines)
    end

    let(:fields) do
      <<~QUERY
        yearPipelines { #{period_fields} }

        yearPipelinesLabels
        yearPipelinesTotals
      QUERY
    end

    it 'contains only requested fields' do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics).keys).to contain_exactly(
        'yearPipelines', 'yearPipelinesLabels', 'yearPipelinesTotals'
      )
    end

    it 'executes exactly 2 queries on ci_pipelines', :use_sql_query_cache do
      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { perform_request }

      expect(recorder.log).to include(a_string_matching(/FROM "ci_pipelines"/)).twice
    end

    it "contains expected data for the year's pipelines" do
      expect(stats).to match(a_hash_including(
        'labels' => ['May 2023', 'June 2023', 'July 2023', 'August 2023', 'September 2023', 'October 2023',
          'November 2023', 'December 2023', 'January 2024', 'February 2024', 'March 2024', 'April 2024',
          'May 2024'],
        'all' => [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 4],
        'success' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        'failed' => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2],
        'other' => [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1]
      ))
    end

    it "contains two arrays of 13 elements each for the year pipelines" do
      perform_request

      expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesTotals).length).to eq(13)
      expect(graphql_data_at(:project, :pipelineAnalytics, :yearPipelinesLabels).length).to eq(13)
    end

    context 'when user has no permissions' do
      let(:user) { guest }

      it { expect(stats).to be_nil }
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
