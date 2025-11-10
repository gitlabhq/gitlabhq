# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability::PipelineToLogs, feature_category: :integrations do
  let(:integration) do
    Struct.new(:otel_endpoint_url, :otel_headers, :service_name, :environment).new(
      'https://example.com/otel',
      {},
      'gitlab-ci',
      'production'
    )
  end

  let(:pipeline_data) do
    {
      object_attributes: {
        id: 123,
        iid: 456,
        name: 'test-pipeline',
        ref: 'main',
        sha: 'abc123',
        status: 'success',
        detailed_status: 'passed',
        created_at: '2023-01-01T10:00:00Z',
        finished_at: '2023-01-01T10:05:00Z',
        duration: 300000,
        queued_duration: 30000,
        protected_ref: true,
        url: 'https://gitlab.com/project/-/pipelines/123',
        stages: %w[test build deploy]
      },
      project: {
        id: 789,
        name: 'test-project'
      },
      builds: [
        {
          id: 1,
          name: 'test-job',
          stage: 'test',
          status: 'success',
          started_at: '2023-01-01T10:01:00Z',
          finished_at: '2023-01-01T10:03:00Z',
          duration: 120000,
          manual: false,
          allow_failure: false,
          runner: {
            id: 1,
            description: 'test-runner',
            tags: %w[docker linux]
          },
          artifacts_file: {
            filename: 'test-results.xml',
            size: 1024
          }
        },
        {
          id: 2,
          name: 'failed-job',
          stage: 'build',
          status: 'failed',
          started_at: '2023-01-01T10:03:00Z',
          finished_at: '2023-01-01T10:04:00Z',
          duration: 60000,
          failure_reason: 'script_failure'
        }
      ]
    }
  end

  let(:converter) { described_class.new(integration, pipeline_data) }

  describe '#convert' do
    it 'returns valid OTEL logs format' do
      result = converter.convert

      aggregate_failures do
        expect(result).to have_key(:resourceLogs)
        expect(result[:resourceLogs]).to be_an(Array)
        expect(result[:resourceLogs].length).to eq(1)
      end
    end

    it 'includes resource attributes' do
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'gitlab-ci' } },
        { key: 'gitlab.project.id', value: { intValue: 789 } },
        { key: 'gitlab.pipeline.id', value: { intValue: 123 } }
      )
    end

    it 'includes pipeline log record' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      aggregate_failures do
        expect(pipeline_log).to be_present
        expect(pipeline_log[:body][:stringValue]).to include('Pipeline success: test-pipeline')
        expect(pipeline_log[:severityText]).to eq('INFO')
      end
    end

    it 'includes job log records' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      job_logs = log_records.select do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'job'
        end
      end
      expect(job_logs.length).to eq(2)

      success_job_log = job_logs.find { |log| log[:body][:stringValue].include?('test-job') }
      aggregate_failures do
        expect(success_job_log).to be_present
        expect(success_job_log[:severityText]).to eq('INFO')
      end

      failed_job_log = job_logs.find { |log| log[:body][:stringValue].include?('failed-job') }
      aggregate_failures do
        expect(failed_job_log).to be_present
        expect(failed_job_log[:severityText]).to eq('ERROR')
      end
    end

    it 'sets correct severity levels' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      aggregate_failures do
        expect(pipeline_log[:severityNumber]).to eq(9) # INFO
        expect(pipeline_log[:severityText]).to eq('INFO')
      end

      failed_job_log = log_records.find { |log| log[:body][:stringValue].include?('failed-job') }
      aggregate_failures do
        expect(failed_job_log[:severityNumber]).to eq(17) # ERROR
        expect(failed_job_log[:severityText]).to eq('ERROR')
      end
    end

    it 'includes pipeline attributes' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      attributes = pipeline_log[:attributes]

      expect(attributes).to include(
        { key: 'pipeline.id', value: { intValue: 123 } },
        { key: 'pipeline.name', value: { stringValue: 'test-pipeline' } },
        { key: 'pipeline.status', value: { stringValue: 'success' } },
        { key: 'pipeline.duration', value: { intValue: 300000 } }
      )
    end

    it 'includes job attributes' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }
      attributes = job_log[:attributes]

      expect(attributes).to include(
        { key: 'job.id', value: { intValue: 1 } },
        { key: 'job.name', value: { stringValue: 'test-job' } },
        { key: 'job.stage', value: { stringValue: 'test' } },
        { key: 'job.status', value: { stringValue: 'success' } },
        { key: 'job.runner.id', value: { intValue: 1 } },
        { key: 'job.artifacts.filename', value: { stringValue: 'test-results.xml' } }
      )
    end

    it 'handles empty pipeline data' do
      empty_data = {}
      converter = described_class.new(integration, empty_data)

      result = converter.convert
      expect(result[:resourceLogs]).to be_empty
    end

    it 'handles missing timestamps gracefully' do
      pipeline_data[:object_attributes].delete(:finished_at)
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      expect(pipeline_log[:timeUnixNano]).to be > 0
    end

    it 'handles invalid timestamps gracefully' do
      time_instance = Time.parse('2023-01-01T10:00:00Z')
      invalid_time = object_double(time_instance, blank?: false)
      allow(invalid_time).to receive(:to_i).and_raise(ArgumentError)
      allow(Time).to receive(:current).and_return(Time.parse('2023-01-01T12:00:00Z'))

      pipeline_data[:object_attributes][:finished_at] = invalid_time
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      expect(pipeline_log[:timeUnixNano]).to be > 0
    end

    it 'includes failure reason for failed jobs' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      failed_job_log = log_records.find { |log| log[:body][:stringValue].include?('failed-job') }
      attributes = failed_job_log[:attributes]

      expect(attributes).to include(
        { key: 'job.failure_reason', value: { stringValue: 'script_failure' } }
      )
    end

    it 'uses custom service name from integration' do
      integration.service_name = 'custom-service'
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'custom-service' } }
      )
    end

    it 'uses custom environment from integration' do
      integration.environment = 'staging'
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'deployment.environment', value: { stringValue: 'staging' } }
      )
    end

    it 'handles different pipeline statuses' do
      pipeline_data[:object_attributes][:status] = 'canceled'
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      expect(pipeline_log[:severityText]).to eq('WARN')
    end

    it 'includes environment attributes correctly' do
      test_cases = [
        {
          environment: { name: 'production', action: 'start' },
          expected_name: 'production',
          expected_action: 'start'
        },
        {
          environment: { name: nil, action: nil },
          expected_name: '',
          expected_action: ''
        }
      ]

      test_cases.each do |test_case|
        pipeline_data[:builds].first[:environment] = test_case[:environment]
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
        job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }
        attributes = job_log[:attributes]

        expect(attributes).to include(
          { key: 'job.environment.name', value: { stringValue: test_case[:expected_name] } },
          { key: 'job.environment.action', value: { stringValue: test_case[:expected_action] } }
        )
      end
    end
  end

  describe '#build_environment_attributes' do
    it 'returns environment attributes correctly' do
      test_cases = [
        {
          build: { name: 'test-job', status: 'success' },
          expected: []
        },
        {
          build: {
            name: 'test-job',
            status: 'success',
            environment: {
              name: 'staging',
              action: 'stop'
            }
          },
          expected: [
            { key: 'job.environment.name', value: { stringValue: 'staging' } },
            { key: 'job.environment.action', value: { stringValue: 'stop' } }
          ]
        }
      ]

      aggregate_failures do
        test_cases.each do |test_case|
          result = converter.send(:build_environment_attributes, test_case[:build])
          expect(result).to eq(test_case[:expected])
        end
      end
    end
  end

  describe '#map_severity' do
    it 'maps status to severity number correctly' do
      test_cases = {
        'success' => 9,
        'failed' => 17,
        'canceled' => 13,
        'running' => 5,
        'pending' => 5,
        nil => 5
      }

      aggregate_failures do
        test_cases.each do |status, expected_severity|
          expect(converter.send(:map_severity, status)).to eq(expected_severity),
            "Expected #{status.inspect} to map to #{expected_severity}"
        end
      end
    end
  end

  describe '#map_severity_text' do
    it 'maps status to severity text correctly' do
      test_cases = {
        'success' => 'INFO',
        'failed' => 'ERROR',
        'canceled' => 'WARN',
        'running' => 'DEBUG',
        'pending' => 'DEBUG',
        nil => 'DEBUG'
      }

      aggregate_failures do
        test_cases.each do |status, expected_severity|
          expect(converter.send(:map_severity_text, status)).to eq(expected_severity),
            "Expected #{status.inspect} to map to #{expected_severity}"
        end
      end
    end
  end

  describe '#time_to_nanoseconds' do
    it 'returns 0 for blank values' do
      aggregate_failures do
        expect(converter.send(:time_to_nanoseconds, nil)).to eq(0)
        expect(converter.send(:time_to_nanoseconds, '')).to eq(0)
      end
    end

    it 'converts valid timestamps to nanoseconds' do
      time = Time.parse('2023-01-01T10:00:00Z')
      expected_nanoseconds = time.to_i * 1_000_000_000

      expect(converter.send(:time_to_nanoseconds, time)).to eq(expected_nanoseconds)
    end

    it 'converts ActiveSupport::TimeWithZone to nanoseconds' do
      time = ActiveSupport::TimeZone['UTC'].parse('2023-01-01T10:00:00Z')
      expected_nanoseconds = time.to_i * 1_000_000_000

      expect(converter.send(:time_to_nanoseconds, time)).to eq(expected_nanoseconds)
    end

    it 'handles ArgumentError and falls back to Time.current' do
      time_instance = Time.parse('2023-01-01T10:00:00Z')
      invalid_time = object_double(time_instance, blank?: false)
      allow(invalid_time).to receive(:to_i).and_raise(ArgumentError)
      allow(Time).to receive(:current).and_return(Time.parse('2023-01-01T12:00:00Z'))
      expected_nanoseconds = Time.current.to_i * 1_000_000_000

      result = converter.send(:time_to_nanoseconds, invalid_time)
      expect(result).to eq(expected_nanoseconds)
    end
  end
end
