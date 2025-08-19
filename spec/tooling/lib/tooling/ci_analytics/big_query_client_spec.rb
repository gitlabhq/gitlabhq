# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/lib/tooling/ci_analytics/big_query_client'

RSpec.describe Tooling::CiAnalytics::BigQueryClient, feature_category: :tooling do
  let(:credentials_path) { '/path/to/credentials.json' }
  let(:mock_bigquery) { instance_double(Google::Cloud::Bigquery::Project) }
  let(:mock_dataset) { instance_double(Google::Cloud::Bigquery::Dataset) }
  let(:mock_table) { instance_double(Google::Cloud::Bigquery::Table) }
  let(:mock_insert_result) { instance_double(Google::Cloud::Bigquery::Table::AsyncInserter::Result) }

  let(:sample_event_data) do
    {
      job_id: 12345,
      pipeline_id: 67890,
      project_id: 278964,
      cache_key: 'ruby-gems-test-key',
      cache_type: 'ruby-gems',
      cache_operation: 'pull',
      cache_result: 'hit',
      cache_operation_duration_seconds: 5.2
    }
  end

  before do
    allow(Google::Cloud::Bigquery).to receive(:new).and_return(mock_bigquery)
    allow(mock_bigquery).to receive(:dataset).with('ci_analytics').and_return(mock_dataset)
  end

  describe '#initialize' do
    it 'creates BigQuery client with correct configuration' do
      described_class.new(credentials_path: credentials_path)

      expect(Google::Cloud::Bigquery).to have_received(:new).with(
        project_id: 'gitlab-qa-resources',
        credentials: '/path/to/credentials.json'
      )
      expect(mock_bigquery).to have_received(:dataset).with('ci_analytics')
    end

    it 'stores dataset reference' do
      client = described_class.new(credentials_path: credentials_path)

      expect(client.instance_variable_get(:@dataset)).to eq(mock_dataset)
    end

    context 'when credentials_path is not provided' do
      it 'raises an error with descriptive message' do
        expect do
          described_class.new(credentials_path: nil)
        end.to raise_error(RuntimeError, 'credentials_path is required')
      end
    end

    context 'when credentials_path is empty string' do
      it 'raises an error with descriptive message' do
        expect do
          described_class.new(credentials_path: '')
        end.to raise_error(RuntimeError, 'credentials_path is required')
      end
    end
  end

  describe '#insert_cache_event' do
    let(:client) { described_class.new(credentials_path: credentials_path) }

    before do
      allow(mock_dataset).to receive(:table).with('cache_events').and_return(mock_table)
      allow(mock_table).to receive(:insert).and_return(mock_insert_result)
      allow(client).to receive(:puts)
    end

    context 'when insertion is successful' do
      before do
        allow(mock_insert_result).to receive(:success?).and_return(true)
      end

      it 'calls insert_into_table with correct parameters' do
        allow(client).to receive(:insert_into_table)

        client.insert_cache_event(sample_event_data)

        expect(client).to have_received(:insert_into_table).with('cache_events', sample_event_data)
      end

      it 'inserts data into BigQuery table' do
        client.insert_cache_event(sample_event_data)

        expect(mock_table).to have_received(:insert).with([sample_event_data])
      end

      it 'completes insert successfully' do
        result = client.insert_cache_event(sample_event_data)

        expect(result).to be_nil
      end
    end

    context 'when insertion fails' do
      let(:error_details) do
        [
          {
            'index' => 0,
            'errors' => [
              {
                'reason' => 'invalid',
                'location' => 'job_id',
                'message' => 'Invalid value'
              }
            ]
          }
        ]
      end

      before do
        allow(mock_insert_result).to receive_messages(
          success?: false,
          insert_errors: error_details
        )
      end

      it 'completes with error handling' do
        result = client.insert_cache_event(sample_event_data)

        expect(result).to be_nil
      end
    end
  end

  describe 'private methods' do
    let(:client) { described_class.new(credentials_path: credentials_path) }

    before do
      allow(client).to receive(:puts)
    end

    describe '#insert_into_table' do
      before do
        allow(mock_dataset).to receive(:table).with('test_table').and_return(mock_table)
        allow(mock_table).to receive(:insert).and_return(mock_insert_result)
      end

      it 'gets table from dataset' do
        allow(mock_insert_result).to receive(:success?).and_return(true)

        client.send(:insert_into_table, 'test_table', sample_event_data)

        expect(mock_dataset).to have_received(:table).with('test_table')
      end

      it 'inserts data as array' do
        allow(mock_insert_result).to receive(:success?).and_return(true)

        client.send(:insert_into_table, 'test_table', sample_event_data)

        expect(mock_table).to have_received(:insert).with([sample_event_data])
      end

      context 'with successful insertion' do
        before do
          allow(mock_insert_result).to receive(:success?).and_return(true)
        end

        it 'completes table insertion successfully' do
          result = client.send(:insert_into_table, 'test_table', sample_event_data)

          expect(result).to be_nil
        end
      end

      context 'with failed insertion' do
        let(:error_message) { 'Column not found: invalid_column' }

        before do
          allow(mock_insert_result).to receive_messages(
            success?: false,
            insert_errors: error_message
          )
        end

        it 'handles insertion errors' do
          result = client.send(:insert_into_table, 'test_table', sample_event_data)

          expect(result).to be_nil
        end
      end
    end
  end

  describe 'constants' do
    it 'has correct GCP project ID' do
      expect(described_class::GCP_PROJECT_ID).to eq('gitlab-qa-resources')
    end

    it 'has correct dataset ID' do
      expect(described_class::DATASET_ID).to eq('ci_analytics')
    end

    it 'has correct cache events table name' do
      expect(described_class::CACHE_EVENTS_TABLE).to eq('cache_events')
    end
  end

  describe 'integration scenarios' do
    let(:client) { described_class.new(credentials_path: credentials_path) }

    before do
      allow(client).to receive(:puts)
    end

    context 'with real-world cache event data' do
      let(:complex_event_data) do
        {
          job_id: 10807300430,
          pipeline_id: 1947304110,
          project_id: 278964,
          merge_request_iid: nil,
          merge_request_target_branch: nil,
          pipeline_source: 'push',
          ref: 'master',
          cache_key: 'ruby-gems-debian-bookworm-ruby-3.2.8-gemfile-Gemfile-22',
          cache_type: 'ruby-gems',
          cache_operation: 'push',
          cache_result: 'created',
          cache_operation_duration_seconds: 87.0,
          cache_size_bytes: nil,
          operation_command: 'bundle install',
          operation_duration_seconds: 331.0,
          operation_success: true,
          job_url: 'https://gitlab.com/gitlab-org/gitlab/-/jobs/10807300430',
          created_at: '2025-07-25T07:51:39Z'
        }
      end

      before do
        allow(mock_dataset).to receive(:table).with('cache_events').and_return(mock_table)
        allow(mock_table).to receive(:insert).and_return(mock_insert_result)
        allow(mock_insert_result).to receive(:success?).and_return(true)
      end

      it 'processes complex event data successfully' do
        result = client.insert_cache_event(complex_event_data)

        expect(result).to be_nil
      end
    end

    context 'when BigQuery service is unavailable' do
      before do
        allow(Google::Cloud::Bigquery).to receive(:new).and_raise(
          Google::Cloud::Error.new('Service unavailable')
        )
      end

      it 'raises appropriate error' do
        expect do
          described_class.new(credentials_path: credentials_path)
        end.to raise_error(Google::Cloud::Error, 'Service unavailable')
      end
    end
  end
end
