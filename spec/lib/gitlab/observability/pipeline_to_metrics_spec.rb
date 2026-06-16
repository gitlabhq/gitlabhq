# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Observability::PipelineToMetrics, feature_category: :observability do
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
        name: 'Build and Test',
        ref: 'main',
        tag: false,
        source: 'push',
        status: 'success',
        duration: 300000,
        queued_duration: 30000
      },
      project: {
        id: 789,
        name: 'test-project',
        web_url: 'https://gitlab.com/test-org/test-project',
        namespace: 'test-org'
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
        { key: 'gitlab.pipeline.id', value: { intValue: 123 } },
        { key: 'cicd.pipeline.name', value: { stringValue: 'Build and Test' } },
        { key: 'vcs.repository.name', value: { stringValue: 'test-project' } },
        { key: 'vcs.repository.url.full', value: { stringValue: 'https://gitlab.com/test-org/test-project' } },
        { key: 'vcs.owner.name', value: { stringValue: 'test-org' } },
        { key: 'vcs.provider.name', value: { stringValue: 'gitlab' } },
        { key: 'vcs.ref.head.name', value: { stringValue: 'main' } },
        { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
      )
    end

    context 'when pipeline name is not set' do
      before do
        pipeline_data[:object_attributes][:name] = nil
      end

      it 'falls back to ref for cicd.pipeline.name' do
        result = converter.convert
        resource = result[:resourceMetrics].first[:resource]

        expect(resource[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'main' } }
        )
      end
    end

    it 'includes pipeline duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |metric| metric[:name] == 'pipeline.duration_seconds' }
      aggregate_failures do
        expect(duration_metric).to be_present
        expect(duration_metric[:gauge][:dataPoints].first[:asDouble]).to eq(300.0)
        expect(duration_metric[:gauge][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'pipeline.status', value: { stringValue: 'success' } },
          { key: 'pipeline.ref', value: { stringValue: 'main' } }
        )
      end
    end

    it 'includes cicd.pipeline.run.duration histogram metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_histogram = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.duration' }
      aggregate_failures do
        expect(duration_histogram).to be_present
        expect(duration_histogram[:unit]).to eq('s')
        expect(duration_histogram[:histogram]).to be_present
        expect(duration_histogram[:histogram][:aggregationTemporality]).to eq('AGGREGATION_TEMPORALITY_DELTA')

        data_point = duration_histogram[:histogram][:dataPoints].first
        expect(data_point[:count]).to eq(1)
        expect(data_point[:sum]).to be_within(0.001).of(300.0)
        expect(data_point[:explicitBounds]).to eq([1, 5, 10, 30, 60, 300, 600, 1800, 3600])
        expect(data_point[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'Build and Test' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } },
          { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'push' } },
          { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
        )
      end
    end

    it 'does not include cicd.pipeline.run.duration when duration is missing' do
      pipeline_data[:object_attributes].delete(:duration)
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_histogram = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.duration' }
      expect(duration_histogram).to be_nil
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

    it 'includes cicd.pipeline.run.count counter' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      run_count = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.count' }
      aggregate_failures do
        expect(run_count).to be_present
        expect(run_count[:unit]).to eq('1')
        expect(run_count[:sum][:isMonotonic]).to be(true)
        expect(run_count[:sum][:aggregationTemporality]).to eq('AGGREGATION_TEMPORALITY_DELTA')
        expect(run_count[:sum][:dataPoints].first[:asInt]).to eq(1)
        expect(run_count[:sum][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'Build and Test' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } },
          { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'push' } },
          { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
        )
      end
    end

    it 'includes job count gauge' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      count_metric = metrics.find { |metric| metric[:name] == 'pipeline.jobs_total' }
      aggregate_failures do
        expect(count_metric).to be_present
        expect(count_metric[:gauge][:dataPoints].first[:asInt]).to eq(2)
        expect(count_metric[:gauge][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'pipeline.status', value: { stringValue: 'success' } },
          { key: 'pipeline.ref', value: { stringValue: 'main' } }
        )
      end
    end

    it 'includes cicd.pipeline.task.total gauge' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      task_total_metric = metrics.find { |metric| metric[:name] == 'cicd.pipeline.task.total' }
      aggregate_failures do
        expect(task_total_metric).to be_present
        expect(task_total_metric[:unit]).to eq('1')
        expect(task_total_metric[:gauge][:dataPoints].first[:asInt]).to eq(2)
        expect(task_total_metric[:gauge][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'Build and Test' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } }
        )
      end
    end

    it 'includes job duration histogram' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |metric| metric[:name] == 'job.duration_seconds' }
      aggregate_failures do
        expect(duration_metric).to be_present
        expect(duration_metric[:histogram][:dataPoints].length).to eq(2)
        expect(duration_metric[:histogram][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'job.stage', value: { stringValue: 'test' } },
          { key: 'pipeline.status', value: { stringValue: 'success' } }
        )
      end
    end

    it 'includes cicd.pipeline.task.duration histogram' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      task_duration_metric = metrics.find { |metric| metric[:name] == 'cicd.pipeline.task.duration' }
      aggregate_failures do
        expect(task_duration_metric).to be_present
        expect(task_duration_metric[:unit]).to eq('s')
        expect(task_duration_metric[:histogram][:dataPoints].length).to eq(2)
        expect(task_duration_metric[:histogram][:aggregationTemporality]).to eq('AGGREGATION_TEMPORALITY_DELTA')
        expect(task_duration_metric[:histogram][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'job.stage', value: { stringValue: 'test' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } },
          { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'push' } },
          { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
        )
      end
    end

    it 'does not include cicd.pipeline.task.duration when builds are empty' do
      pipeline_data[:builds] = []
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      task_duration_metric = metrics.find { |metric| metric[:name] == 'cicd.pipeline.task.duration' }
      expect(task_duration_metric).to be_nil
    end

    it 'includes queue duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      queue_metric = metrics.find { |metric| metric[:name] == 'pipeline.queue_duration_seconds' }
      aggregate_failures do
        expect(queue_metric).to be_present
        expect(queue_metric[:gauge][:dataPoints].first[:asDouble]).to eq(30.0)
        expect(queue_metric[:gauge][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'pipeline.status', value: { stringValue: 'success' } },
          { key: 'pipeline.ref', value: { stringValue: 'main' } }
        )
      end
    end

    it 'includes cicd.pipeline.run.queue_duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      queue_duration = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.queue_duration' }
      aggregate_failures do
        expect(queue_duration).to be_present
        expect(queue_duration[:unit]).to eq('s')
        expect(queue_duration[:gauge][:dataPoints].first[:asDouble]).to be_within(0.001).of(30.0)
        expect(queue_duration[:gauge][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'Build and Test' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } }
        )
      end
    end

    it 'does not include cicd.pipeline.run.queue_duration when queued_duration is missing' do
      pipeline_data[:object_attributes].delete(:queued_duration)
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      queue_duration = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.queue_duration' }
      expect(queue_duration).to be_nil
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

      expect(data_point[:attributes]).to contain_exactly(
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

    it 'does not have duplicate metric names for semconv metrics' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      semconv_names = metrics.map { |m| m[:name] }.select { |n| n.start_with?('cicd.') }
      expect(semconv_names).to eq(semconv_names.uniq)
    end

    context 'when pipeline is for a tag' do
      before do
        pipeline_data[:object_attributes][:tag] = true
      end

      it 'emits vcs.ref.head.type as tag' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        run_count = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.count' }
        data_point = run_count[:sum][:dataPoints].first

        expect(data_point[:attributes]).to include(
          { key: 'vcs.ref.head.type', value: { stringValue: 'tag' } }
        )
      end

      it 'sets vcs.ref.head.type to tag in resource attributes' do
        result = converter.convert
        resource = result[:resourceMetrics].first[:resource]

        expect(resource[:attributes]).to include(
          { key: 'vcs.ref.head.type', value: { stringValue: 'tag' } }
        )
      end
    end

    context 'with pipeline result mapping' do
      using RSpec::Parameterized::TableSyntax

      where(:gitlab_status, :expected_result) do
        'success'  | 'success'
        'failed'   | 'failure'
        'canceled' | 'cancellation'
        'skipped'  | 'skip'
        'running'  | 'running'
      end

      with_them do
        before do
          pipeline_data[:object_attributes][:status] = gitlab_status
          pipeline_data[:object_attributes][:duration] = 300000
        end

        it 'maps pipeline status to OTel result enum' do
          result = converter.convert
          metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

          run_count = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.count' }
          data_point = run_count[:sum][:dataPoints].first

          expect(data_point[:attributes]).to include(
            { key: 'cicd.pipeline.result', value: { stringValue: expected_result } }
          )
        end
      end
    end

    context 'when pipeline has failed' do
      before do
        pipeline_data[:object_attributes][:status] = 'failed'
      end

      it 'includes cicd.pipeline.run.errors metric' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        errors_metric = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.errors' }
        aggregate_failures do
          expect(errors_metric).to be_present
          expect(errors_metric[:unit]).to eq('{error}')
          expect(errors_metric[:sum][:isMonotonic]).to be(true)
          expect(errors_metric[:sum][:dataPoints].first[:asInt]).to eq(1)
          expect(errors_metric[:sum][:dataPoints].first[:attributes]).to contain_exactly(
            { key: 'cicd.pipeline.name', value: { stringValue: 'Build and Test' } },
            { key: 'error.type', value: { stringValue: '_OTHER' } }
          )
        end
      end
    end

    context 'when pipeline has succeeded' do
      it 'does not include cicd.pipeline.run.errors metric' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        errors_metric = metrics.find { |metric| metric[:name] == 'cicd.pipeline.run.errors' }
        expect(errors_metric).to be_nil
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
