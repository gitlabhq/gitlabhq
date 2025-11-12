# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability::PipelineToTraces, feature_category: :integrations do
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
        created_at: Time.zone.parse('2023-01-01T10:00:00Z'),
        finished_at: Time.zone.parse('2023-01-01T10:05:00Z'),
        duration: 300000,
        queued_duration: 30000,
        protected_ref: true,
        url: 'https://gitlab.com/project/-/pipelines/123'
      },
      project: {
        id: 789,
        name: 'test-project',
        path_with_namespace: 'group/test-project'
      },
      builds: [
        {
          id: 1,
          name: 'test-job',
          stage: 'test',
          status: 'success',
          started_at: Time.zone.parse('2023-01-01T10:01:00Z'),
          finished_at: Time.zone.parse('2023-01-01T10:03:00Z'),
          duration: 120000,
          manual: false,
          allow_failure: false,
          runner: {
            id: 1,
            description: 'test-runner',
            tags: %w[docker linux]
          }
        }
      ]
    }
  end

  let(:converter) { described_class.new(integration, pipeline_data) }

  def convert_result
    converter.convert
  end

  def spans
    convert_result[:resourceSpans].first[:scopeSpans].first[:spans]
  end

  def pipeline_span
    spans.find { |span| span[:name].start_with?('pipeline:') }
  end

  def job_span
    spans.find { |span| span[:name].start_with?('job:') }
  end

  def resource
    convert_result[:resourceSpans].first[:resource]
  end

  describe '#convert' do
    it 'returns valid OTEL traces format' do
      result = convert_result

      aggregate_failures do
        expect(result).to have_key(:resourceSpans)
        expect(result[:resourceSpans]).to be_an(Array)
        expect(result[:resourceSpans].length).to eq(1)
      end
    end

    it 'includes resource attributes' do
      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'gitlab-ci' } },
        { key: 'gitlab.project.id', value: { intValue: 789 } },
        { key: 'gitlab.pipeline.id', value: { intValue: 123 } }
      )
    end

    it 'includes pipeline span' do
      aggregate_failures do
        expect(pipeline_span).to be_present
        expect(pipeline_span[:name]).to eq('pipeline: test-pipeline')
        expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_OK')
      end
    end

    it 'sets correct timestamps' do
      aggregate_failures do
        expect(pipeline_span[:startTimeUnixNano]).to eq(1672567200000000000)
        expect(pipeline_span[:endTimeUnixNano]).to eq(1672567500000000000)
      end
    end

    it 'handles failed job status' do
      pipeline_data[:builds].first[:status] = 'failed'
      pipeline_data[:builds].first[:failure_reason] = 'runner_system_failure'

      aggregate_failures do
        expect(job_span[:status][:code]).to eq('STATUS_CODE_ERROR')
        expect(job_span[:status][:message]).to eq('runner_system_failure')
      end
    end

    it 'handles unhandled pipeline status with STATUS_CODE_UNSET' do
      pipeline_data[:object_attributes][:status] = 'running'

      expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_UNSET')
    end

    it 'handles unhandled job status with STATUS_CODE_UNSET' do
      pipeline_data[:builds].first[:status] = 'pending'

      expect(job_span[:status][:code]).to eq('STATUS_CODE_UNSET')
    end

    it 'handles unhandled status with message' do
      pipeline_data[:object_attributes][:status] = 'skipped'
      pipeline_data[:object_attributes][:failure_reason] = 'manual_skip'

      aggregate_failures do
        expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_UNSET')
        expect(pipeline_span[:status][:message]).to eq('manual_skip')
      end
    end

    it 'does not include status message when failure_reason is absent' do
      pipeline_data[:object_attributes][:status] = 'success'

      aggregate_failures do
        expect(pipeline_span[:status][:code]).to eq('STATUS_CODE_OK')
        expect(pipeline_span[:status]).not_to have_key(:message)
      end
    end

    it 'includes job attributes' do
      attributes = job_span[:attributes]

      expect(attributes).to include(
        { key: 'job.id', value: { intValue: 1 } },
        { key: 'job.name', value: { stringValue: 'test-job' } },
        { key: 'job.stage', value: { stringValue: 'test' } },
        { key: 'job.runner.id', value: { intValue: 1 } },
        { key: 'job.runner.description', value: { stringValue: 'test-runner' } }
      )
    end

    it 'handles empty pipeline data' do
      empty_data = {}
      converter = described_class.new(integration, empty_data)

      result = converter.convert
      expect(result[:resourceSpans]).to be_empty
    end

    it 'handles missing timestamps gracefully' do
      pipeline_data[:object_attributes].delete(:created_at)
      pipeline_data[:object_attributes].delete(:finished_at)

      aggregate_failures do
        expect(pipeline_span[:startTimeUnixNano]).to eq(0)
        expect(pipeline_span[:endTimeUnixNano]).to eq(0)
      end
    end

    it 'uses custom service name from integration' do
      integration.service_name = 'custom-service'

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'custom-service' } }
      )
    end

    it 'uses custom environment from integration' do
      integration.environment = 'staging'

      expect(resource[:attributes]).to include(
        { key: 'deployment.environment', value: { stringValue: 'staging' } }
      )
    end

    it 'sets up trace and span IDs correctly' do
      job_spans = spans.select { |span| span[:name].start_with?('job:') }

      aggregate_failures do
        expect(pipeline_span[:traceId]).to match(/\A[0-9a-f]{32}\z/)
        expect(pipeline_span[:traceId].length).to eq(32)
      end

      job_spans.each do |job_span|
        expect(job_span[:traceId]).to eq(pipeline_span[:traceId])
      end

      aggregate_failures do
        expect(pipeline_span[:spanId]).to match(/\A[0-9a-f]{16}\z/)
        expect(pipeline_span[:spanId].length).to eq(16)
        expect(pipeline_span[:parentSpanId]).to eq('')
      end

      job_spans.each do |job_span|
        aggregate_failures do
          expect(job_span[:spanId]).to match(/\A[0-9a-f]{16}\z/)
          expect(job_span[:spanId].length).to eq(16)
          expect(job_span[:parentSpanId]).to eq(pipeline_span[:spanId])
        end
      end

      all_span_ids = [pipeline_span[:spanId]] + job_spans.pluck(:spanId)
      expect(all_span_ids.uniq.length).to eq(all_span_ids.length)
    end

    context 'with optional pipeline attributes' do
      before do
        pipeline_data[:object_attributes][:tag] = true
        pipeline_data[:object_attributes][:before_sha] = 'def456'
        pipeline_data[:object_attributes][:stages] = %w[build test deploy]
        pipeline_data[:user] = { id: 42, username: 'testuser' }
        pipeline_data[:commit] = { id: 'abc123', message: 'Test commit' }
        pipeline_data[:merge_request] = { id: 100, iid: 10 }
        pipeline_data[:source_pipeline] = { pipeline_id: 999 }
      end

      it 'includes optional pipeline attributes when present' do
        attributes = pipeline_span[:attributes]

        expect(attributes).to include(
          { key: 'pipeline.tag', value: { boolValue: true } },
          { key: 'pipeline.before_sha', value: { stringValue: 'def456' } },
          { key: 'pipeline.stages', value: { arrayValue: { values: [
            { stringValue: 'build' },
            { stringValue: 'test' },
            { stringValue: 'deploy' }
          ] } } },
          { key: 'pipeline.user.id', value: { intValue: 42 } },
          { key: 'pipeline.user.username', value: { stringValue: 'testuser' } },
          { key: 'pipeline.commit.id', value: { stringValue: 'abc123' } },
          { key: 'pipeline.commit.message', value: { stringValue: 'Test commit' } },
          { key: 'pipeline.merge_request.id', value: { intValue: 100 } },
          { key: 'pipeline.merge_request.iid', value: { intValue: 10 } },
          { key: 'pipeline.source_pipeline.pipeline_id', value: { intValue: 999 } }
        )
      end
    end

    context 'with optional job attributes' do
      before do
        pipeline_data[:builds].first[:created_at] = Time.zone.parse('2023-01-01T10:00:30Z')
        pipeline_data[:builds].first[:when] = 'on_success'
        pipeline_data[:builds].first[:user] = { id: 43, username: 'jobuser' }
        pipeline_data[:builds].first[:artifacts_file] = { filename: 'artifact.zip', size: 1024 }
        pipeline_data[:builds].first[:runner][:runner_type] = 'instance_type'
        pipeline_data[:builds].first[:runner][:active] = true
        pipeline_data[:builds].first[:runner][:is_shared] = true
        pipeline_data[:builds].first[:environment] = {
          name: 'production',
          action: 'start',
          deployment_tier: 'production'
        }
      end

      it 'includes optional job attributes when present' do
        attributes = job_span[:attributes]

        expect(attributes).to include(
          { key: 'job.created_at', value: { intValue: 1672567230000000000 } },
          { key: 'job.when', value: { stringValue: 'on_success' } },
          { key: 'job.user.id', value: { intValue: 43 } },
          { key: 'job.user.username', value: { stringValue: 'jobuser' } },
          { key: 'job.artifacts.filename', value: { stringValue: 'artifact.zip' } },
          { key: 'job.artifacts.size', value: { intValue: 1024 } },
          { key: 'job.runner.type', value: { stringValue: 'instance_type' } },
          { key: 'job.runner.active', value: { boolValue: true } },
          { key: 'job.runner.is_shared', value: { boolValue: true } },
          { key: 'job.environment.deployment_tier', value: { stringValue: 'production' } }
        )
      end
    end

    it 'does not include optional attributes when data is missing' do
      pipeline_attrs = pipeline_span[:attributes].pluck(:key)
      job_attrs = job_span[:attributes].pluck(:key)

      missing_pipeline_attrs = %w[
        pipeline.tag
        pipeline.before_sha
        pipeline.stages
        pipeline.user.id
        pipeline.commit.id
        pipeline.merge_request.id
        pipeline.source_pipeline.pipeline_id
      ]

      missing_job_attrs = %w[
        job.created_at
        job.when
        job.user.id
        job.artifacts.filename
        job.runner.type
        job.environment.deployment_tier
      ]

      missing_pipeline_attrs.each do |attr|
        expect(pipeline_attrs).not_to include(attr)
      end

      missing_job_attrs.each do |attr|
        expect(job_attrs).not_to include(attr)
      end
    end
  end
end
