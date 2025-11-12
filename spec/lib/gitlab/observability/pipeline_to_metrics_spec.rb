# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability::PipelineToMetrics, feature_category: :integrations do
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
        ref: 'main',
        status: 'success',
        duration: 300000,
        queued_duration: 30000
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
          duration: 120000
        },
        {
          id: 2,
          name: 'build-job',
          stage: 'build',
          status: 'success',
          duration: 180000
        }
      ]
    }
  end

  let(:converter) { described_class.new(integration, pipeline_data) }

  describe '#convert' do
    it 'returns valid OTEL metrics format' do
      result = converter.convert

      expect(result).to have_key(:resourceMetrics)
      expect(result[:resourceMetrics]).to be_an(Array)
      expect(result[:resourceMetrics].length).to eq(1)
    end

    it 'includes resource attributes' do
      result = converter.convert
      resource = result[:resourceMetrics].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'gitlab-ci' } },
        { key: 'gitlab.project.id', value: { intValue: 789 } },
        { key: 'gitlab.pipeline.id', value: { intValue: 123 } }
      )
    end

    it 'includes pipeline duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |metric| metric[:name] == 'pipeline.duration_seconds' }
      aggregate_failures do
        expect(duration_metric).to be_present
        expect(duration_metric[:gauge][:dataPoints].first[:asDouble]).to eq(300.0) # 5 minutes in seconds
      end
    end

    it 'includes pipeline status counter' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      status_metric = metrics.find { |metric| metric[:name] == 'pipeline.status_total' }
      aggregate_failures do
        expect(status_metric).to be_present
        expect(status_metric[:sum][:dataPoints].first[:asInt]).to eq(1)
      end
    end

    it 'includes job count gauge' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      count_metric = metrics.find { |metric| metric[:name] == 'pipeline.jobs_total' }
      aggregate_failures do
        expect(count_metric).to be_present
        expect(count_metric[:gauge][:dataPoints].first[:asInt]).to eq(2)
      end
    end

    it 'includes job duration histogram' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |metric| metric[:name] == 'job.duration_seconds' }
      aggregate_failures do
        expect(duration_metric).to be_present
        expect(duration_metric[:histogram][:dataPoints].length).to eq(2) # One for each stage
      end
    end

    it 'includes queue duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      queue_metric = metrics.find { |metric| metric[:name] == 'pipeline.queue_duration_seconds' }
      aggregate_failures do
        expect(queue_metric).to be_present
        expect(queue_metric[:gauge][:dataPoints].first[:asDouble]).to eq(30.0) # 30 seconds
      end
    end

    it 'handles empty pipeline data' do
      empty_data = {}
      converter = described_class.new(integration, empty_data)

      result = converter.convert
      expect(result[:resourceMetrics]).to be_empty
    end

    it 'handles missing duration gracefully' do
      pipeline_data[:object_attributes].delete(:duration)
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |metric| metric[:name] == 'pipeline.duration_seconds' }
      expect(duration_metric).to be_nil
    end

    it 'handles missing builds gracefully' do
      pipeline_data[:builds] = []
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |metric| metric[:name] == 'job.duration_seconds' }
      expect(duration_metric).to be_nil
    end

    it 'includes correct attributes in metrics' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      status_metric = metrics.find { |metric| metric[:name] == 'pipeline.status_total' }
      data_point = status_metric[:sum][:dataPoints].first

      expect(data_point[:attributes]).to include(
        { key: 'pipeline.status', value: { stringValue: 'success' } },
        { key: 'pipeline.ref', value: { stringValue: 'main' } }
      )
    end

    it 'builds histogram buckets correctly' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |metric| metric[:name] == 'job.duration_seconds' }
      data_point = duration_metric[:histogram][:dataPoints].first

      aggregate_failures do
        expect(data_point[:count]).to eq(1)
        expect(data_point[:sum]).to eq(120000)
        expect(data_point[:bucketCounts]).to be_an(Array)
        expect(data_point[:explicitBounds]).to match_array([1, 5, 10, 30, 60, 300, 600, 1800, 3600])
      end
    end

    it 'uses custom service name from integration' do
      integration.service_name = 'custom-service'
      result = converter.convert
      resource = result[:resourceMetrics].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'custom-service' } }
      )
    end

    it 'uses custom environment from integration' do
      integration.environment = 'staging'
      result = converter.convert
      resource = result[:resourceMetrics].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'deployment.environment', value: { stringValue: 'staging' } }
      )
    end
  end
end
