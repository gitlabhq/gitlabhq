# frozen_string_literal: true

require 'fast_spec_helper'

# Mock required classes since we're testing the script logic, not the dependencies
# rubocop:disable Lint/EmptyClass -- Mock classes for testing don't need implementation
module Tooling
  module CiAnalytics
    class JobTraceDownloader; end
    class BigQueryClient; end
    class CacheLogParser; end
    class CacheEventBuilder; end
  end

  module Events
    class TrackPipelineEvents; end
  end
end
# rubocop:enable Lint/EmptyClass

# Load the CacheMetrics class definition without executing the script
load File.expand_path('../../scripts/cache_metrics', __dir__)

RSpec.describe 'scripts/cache_metrics', feature_category: :tooling do
  let(:mock_trace_downloader) { instance_double(Tooling::CiAnalytics::JobTraceDownloader) }
  let(:mock_bigquery_client) { instance_double(Tooling::CiAnalytics::BigQueryClient) }
  let(:mock_cache_event_builder) { instance_double(Tooling::CiAnalytics::CacheEventBuilder) }
  let(:mock_events_tracker) { instance_double(Tooling::Events::TrackPipelineEvents) }

  let(:ci_env) do
    {
      job_id: '12345',
      job_name: 'rspec-unit pg16',
      pipeline_id: '67890',
      project_id: '278964',
      merge_request_iid: '199241',
      merge_request_target_branch: 'master',
      pipeline_source: 'merge_request_event',
      ref: 'feature-branch',
      job_url: 'https://gitlab.com/gitlab-org/gitlab/-/jobs/12345'
    }
  end

  let(:sample_job_trace) do
    <<~TRACE
      2025-07-24T14:11:26.953582Z Checking cache for ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22...
      2025-07-24T14:11:35.382214Z Successfully extracted cache
      2025-07-24T14:11:46.639408Z Installing gems
      2025-07-24T14:11:50.334110Z Bundle complete!
    TRACE
  end

  let(:sample_cache_events) do
    [
      {
        cache_key: 'ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22',
        cache_type: 'ruby-gems',
        cache_operation: 'pull',
        cache_result: 'hit',
        duration: 5.2,
        operation_command: 'bundle install',
        operation_duration: 3.5,
        operation_success: true
      },
      {
        cache_key: 'node-modules-debian-bookworm-test-22',
        cache_type: 'node-modules',
        cache_operation: 'pull',
        cache_result: 'miss',
        duration: 15.0,
        operation_command: 'yarn install',
        operation_duration: 25.3,
        operation_success: true
      }
    ]
  end

  let(:sample_bigquery_event) do
    {
      job_id: 12345,
      cache_key: 'ruby-gems-test',
      cache_type: 'ruby-gems',
      cache_operation: 'pull',
      cache_result: 'hit',
      job_url: 'https://gitlab.com/gitlab-org/gitlab/-/jobs/12345',
      created_at: '2025-07-25T10:30:00Z'
    }
  end

  let(:sample_internal_event_properties) do
    {
      label: 'hit',
      property: 'ruby-gems',
      value: 5.2,
      extra_properties: {
        cache_key: 'ruby-gems-test',
        cache_operation: 'pull',
        job_id: 12345,
        pipeline_id: 67890,
        ref: 'feature-branch',
        operation_command: 'bundle install',
        operation_duration_seconds: 3.5,
        operation_success: true
      }
    }
  end

  before do
    # Mock ENV variables needed by the script
    stub_env('CI_API_V4_URL', 'https://gitlab.com/api/v4')
    stub_env('CI_INTERNAL_EVENTS_TOKEN', 'internal-events-token')
    stub_env('GLCI_BIGQUERY_CREDENTIALS_PATH', '/tmp/bigquery-credentials.json')

    allow(Tooling::CiAnalytics::JobTraceDownloader).to receive(:new).and_return(mock_trace_downloader)
    allow(Tooling::CiAnalytics::BigQueryClient).to receive(:new).and_return(mock_bigquery_client)
    allow(Tooling::CiAnalytics::CacheEventBuilder).to receive(:new).and_return(mock_cache_event_builder)
    allow(Tooling::Events::TrackPipelineEvents).to receive(:new).and_return(mock_events_tracker)

    allow(Tooling::CiAnalytics::CacheLogParser).to receive(:extract_cache_events)

    # Mock all puts output globally
    allow(Tooling::CiAnalytics::CacheMetrics).to receive(:puts)
    allow(Tooling::CiAnalytics::CacheMetrics).to receive(:exit)

    allow(Tooling::CiAnalytics::CacheMetrics).to receive(:cache_metrics_ci_environment).and_return(ci_env)
  end

  describe '.run' do
    context 'when cache events are found' do
      before do
        allow(mock_trace_downloader).to receive(:download_job_trace).and_return(sample_job_trace)
        allow(Tooling::CiAnalytics::CacheLogParser).to receive(:extract_cache_events).and_return(sample_cache_events)
        allow(mock_cache_event_builder).to receive_messages(
          build_bigquery_event: sample_bigquery_event,
          build_internal_event_properties: sample_internal_event_properties
        )
        allow(mock_bigquery_client).to receive(:insert_cache_event)
        allow(mock_events_tracker).to receive(:send_event)
      end

      it 'creates trace downloader with correct parameters' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(Tooling::CiAnalytics::JobTraceDownloader).to have_received(:new).with(
          api_url: 'https://gitlab.com/api/v4',
          token: 'internal-events-token',
          project_id: '278964'
        )
      end

      it 'creates BigQuery client with correct parameters' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(Tooling::CiAnalytics::BigQueryClient).to have_received(:new).with(
          credentials_path: '/tmp/bigquery-credentials.json'
        )
      end

      it 'creates cache event builder with CI environment' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(Tooling::CiAnalytics::CacheEventBuilder).to have_received(:new).with(ci_env)
      end

      it 'downloads job trace' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(mock_trace_downloader).to have_received(:download_job_trace).with('12345')
      end

      it 'extracts cache events from trace' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(Tooling::CiAnalytics::CacheLogParser).to have_received(:extract_cache_events).with(sample_job_trace)
      end

      it 'processes each cache event' do
        Tooling::CiAnalytics::CacheMetrics.run

        sample_cache_events.each do |cache_data|
          expect(mock_cache_event_builder).to have_received(:build_bigquery_event).with(cache_data)
          expect(mock_cache_event_builder).to have_received(:build_internal_event_properties).with(cache_data)
        end
      end

      it 'inserts events into BigQuery' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(mock_bigquery_client).to have_received(:insert_cache_event).twice
      end

      it 'sends internal events with correct parameters' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(mock_events_tracker).to have_received(:send_event).with(
          'glci_cache_operation',
          label: 'hit',
          property: 'ruby-gems',
          value: 5.2,
          extra_properties: hash_including(
            cache_key: 'ruby-gems-test',
            cache_operation: 'pull',
            job_id: 12345
          )
        ).twice
      end

      it 'completes successfully' do
        expect { Tooling::CiAnalytics::CacheMetrics.run }.not_to raise_error
      end
    end

    context 'when no job trace is available' do
      before do
        allow(mock_trace_downloader).to receive(:download_job_trace).and_return(nil)
        allow(mock_bigquery_client).to receive(:insert_cache_event)
        allow(mock_events_tracker).to receive(:send_event)
      end

      it 'returns early without processing' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(Tooling::CiAnalytics::CacheLogParser).not_to have_received(:extract_cache_events)
        expect(mock_bigquery_client).not_to have_received(:insert_cache_event)
        expect(mock_events_tracker).not_to have_received(:send_event)
      end
    end

    context 'when no cache events are found' do
      before do
        allow(mock_trace_downloader).to receive(:download_job_trace).and_return(sample_job_trace)
        allow(Tooling::CiAnalytics::CacheLogParser).to receive(:extract_cache_events).and_return([])
        allow(mock_bigquery_client).to receive(:insert_cache_event)
        allow(mock_events_tracker).to receive(:send_event)
      end

      it 'returns early without processing events' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(mock_bigquery_client).not_to have_received(:insert_cache_event)
        expect(mock_events_tracker).not_to have_received(:send_event)
      end
    end

    context 'when an error occurs' do
      let(:error_message) { 'BigQuery connection failed' }

      before do
        allow(mock_trace_downloader).to receive(:download_job_trace).and_raise(StandardError.new(error_message))
      end

      it 'handles errors gracefully' do
        expect { Tooling::CiAnalytics::CacheMetrics.run }.not_to raise_error
      end

      it 'calls exit with code 0' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(Tooling::CiAnalytics::CacheMetrics).to have_received(:exit).with(0)
      end
    end

    context 'with missing environment variables' do
      before do
        allow(Tooling::CiAnalytics::CacheMetrics).to receive(:cache_metrics_ci_environment).and_return(
          ci_env.merge(job_id: nil)
        )
        allow(mock_trace_downloader).to receive(:download_job_trace).and_return(sample_job_trace)
        allow(Tooling::CiAnalytics::CacheLogParser).to receive(:extract_cache_events).and_return(sample_cache_events)
        allow(mock_cache_event_builder).to receive_messages(
          build_bigquery_event: sample_bigquery_event,
          build_internal_event_properties: sample_internal_event_properties
        )
        allow(mock_bigquery_client).to receive(:insert_cache_event)
        allow(mock_events_tracker).to receive(:send_event)
      end

      it 'continues processing with nil job ID' do
        expect { Tooling::CiAnalytics::CacheMetrics.run }.not_to raise_error
      end
    end
  end

  describe 'integration scenarios' do
    context 'with real-world cache data' do
      let(:complex_cache_events) do
        [
          {
            cache_key: 'ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22',
            cache_type: 'ruby-gems',
            cache_operation: 'pull',
            cache_result: 'hit',
            duration: 9.0,
            cache_size_bytes: nil,
            operation_command: 'bundle install',
            operation_duration: 4.0,
            operation_success: true
          },
          {
            cache_key: 'go-pkg-debian-bookworm-22',
            cache_type: 'go',
            cache_operation: 'push',
            cache_result: 'created',
            duration: 118.0,
            cache_size_bytes: nil,
            operation_command: nil,
            operation_duration: nil,
            operation_success: nil
          }
        ]
      end

      before do
        allow(mock_trace_downloader).to receive(:download_job_trace).and_return(sample_job_trace)
        allow(Tooling::CiAnalytics::CacheLogParser).to receive(:extract_cache_events).and_return(complex_cache_events)
        allow(mock_cache_event_builder).to receive_messages(
          build_bigquery_event: sample_bigquery_event,
          build_internal_event_properties: sample_internal_event_properties
        )
        allow(mock_bigquery_client).to receive(:insert_cache_event)
        allow(mock_events_tracker).to receive(:send_event)
      end

      it 'processes complex cache scenarios correctly' do
        Tooling::CiAnalytics::CacheMetrics.run

        expect(mock_bigquery_client).to have_received(:insert_cache_event).twice
        expect(mock_events_tracker).to have_received(:send_event).twice
      end

      it 'handles different cache types and operations' do
        Tooling::CiAnalytics::CacheMetrics.run

        complex_cache_events.each do |cache_data|
          expect(mock_cache_event_builder).to have_received(:build_bigquery_event).with(cache_data)
          expect(mock_cache_event_builder).to have_received(:build_internal_event_properties).with(cache_data)
        end
      end
    end

    context 'when BigQuery fails but internal events succeed' do
      before do
        allow(mock_trace_downloader).to receive(:download_job_trace).and_return(sample_job_trace)
        sample_events = [sample_cache_events.first]
        allow(Tooling::CiAnalytics::CacheLogParser).to receive(:extract_cache_events).and_return(sample_events)
        allow(mock_cache_event_builder).to receive_messages(
          build_bigquery_event: sample_bigquery_event,
          build_internal_event_properties: sample_internal_event_properties
        )
        allow(mock_bigquery_client).to receive(:insert_cache_event).and_raise(StandardError.new('BigQuery error'))
        allow(mock_events_tracker).to receive(:send_event)
      end

      it 'continues processing despite BigQuery errors' do
        expect { Tooling::CiAnalytics::CacheMetrics.run }.not_to raise_error
      end
    end
  end

  describe 'class structure' do
    it 'is defined within correct module namespace' do
      expect(Tooling::CiAnalytics::CacheMetrics.name).to eq('Tooling::CiAnalytics::CacheMetrics')
    end

    it 'responds to run class method' do
      expect(Tooling::CiAnalytics::CacheMetrics).to respond_to(:run)
    end
  end

  describe 'extra_properties extraction' do
    let(:mock_properties) do
      {
        label: 'hit',
        property: 'ruby-gems',
        value: 5.2,
        extra_properties: {
          cache_key: 'ruby-gems-test',
          cache_operation: 'pull',
          job_id: 12345,
          pipeline_id: 67890,
          ref: 'feature-branch',
          operation_command: 'bundle install',
          operation_duration_seconds: 3.5,
          operation_success: true
        }
      }
    end

    before do
      allow(mock_trace_downloader).to receive(:download_job_trace).and_return(sample_job_trace)
      sample_events = [sample_cache_events.first]
      allow(Tooling::CiAnalytics::CacheLogParser).to receive(:extract_cache_events).and_return(sample_events)
      allow(mock_cache_event_builder).to receive_messages(
        build_bigquery_event: sample_bigquery_event,
        build_internal_event_properties: mock_properties
      )
      allow(mock_bigquery_client).to receive(:insert_cache_event)
      allow(mock_events_tracker).to receive(:send_event)
    end

    it 'sends all extra_properties data' do
      expected_extra_properties = {
        cache_key: 'ruby-gems-test',
        cache_operation: 'pull',
        job_id: 12345,
        pipeline_id: 67890,
        ref: 'feature-branch',
        operation_command: 'bundle install',
        operation_duration_seconds: 3.5,
        operation_success: true
      }

      Tooling::CiAnalytics::CacheMetrics.run

      expect(mock_events_tracker).to have_received(:send_event).with(
        'glci_cache_operation',
        label: 'hit',
        property: 'ruby-gems',
        value: 5.2,
        extra_properties: expected_extra_properties
      )
    end
  end

  describe '.cache_metrics_ci_environment' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      stub_env('CI_JOB_ID', '12345')
      stub_env('CI_JOB_NAME', 'rspec-unit pg16')
      stub_env('CI_PIPELINE_ID', '67890')
      stub_env('CI_PROJECT_ID', '278964')
      stub_env('CI_MERGE_REQUEST_IID', '199241')
      stub_env('CI_MERGE_REQUEST_TARGET_BRANCH_NAME', 'master')
      stub_env('CI_PIPELINE_SOURCE', 'merge_request_event')
      stub_env('CI_COMMIT_REF_NAME', 'feature-branch')
      stub_env('CI_JOB_URL', 'https://gitlab.com/gitlab-org/gitlab/-/jobs/12345')
    end

    it 'builds CI environment hash from ENV variables' do
      allow(Tooling::CiAnalytics::CacheMetrics).to receive(:cache_metrics_ci_environment).and_call_original

      result = Tooling::CiAnalytics::CacheMetrics.cache_metrics_ci_environment

      expect(result).to eq({
        job_id: '12345',
        job_name: 'rspec-unit pg16',
        pipeline_id: '67890',
        project_id: '278964',
        merge_request_iid: '199241',
        merge_request_target_branch: 'master',
        pipeline_source: 'merge_request_event',
        ref: 'feature-branch',
        job_url: 'https://gitlab.com/gitlab-org/gitlab/-/jobs/12345'
      })
    end

    it 'memoizes the result' do
      allow(Tooling::CiAnalytics::CacheMetrics).to receive(:cache_metrics_ci_environment).and_call_original

      first_call = Tooling::CiAnalytics::CacheMetrics.cache_metrics_ci_environment
      second_call = Tooling::CiAnalytics::CacheMetrics.cache_metrics_ci_environment

      expect(first_call).to be(second_call) # same object reference
    end
  end
end
