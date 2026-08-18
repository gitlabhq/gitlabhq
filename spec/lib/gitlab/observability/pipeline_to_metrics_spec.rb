# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../lib/gitlab/ci/trace_context'
require_relative '../../../support/shared_contexts/lib/gitlab/observability/pipeline_converter_shared_context'

RSpec.describe Gitlab::Observability::PipelineToMetrics, feature_category: :observability do
  include_context 'with pipeline converter data'

  let(:pipeline_data) do
    base_pipeline_data.deep_merge(
      object_attributes: {
        tag: false
      }
    )
  end

  let(:converter) { described_class.new(integration, pipeline_data) }

  describe '#convert' do
    it 'returns valid OTEL metrics format' do
      result = converter.convert

      aggregate_failures do
        expect(result).to have_key(:resourceMetrics)
        expect(result[:resourceMetrics]).to be_an(Array)
        expect(result[:resourceMetrics].length).to eq(1)
      end
    end

    it 'includes resource attributes' do
      result = converter.convert
      resource = result[:resourceMetrics].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'gitlab-ci' } },
        { key: 'vcs.provider.name', value: { stringValue: 'gitlab' } },
        { key: 'vcs.repository.name', value: { stringValue: 'test-project' } },
        { key: 'vcs.owner.name', value: { stringValue: 'test-org' } }
      )
    end

    it 'includes gitlab.cicd.pipeline.trace_id in resource' do
      result = converter.convert
      resource = result[:resourceMetrics].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'gitlab.cicd.pipeline.trace_id', value: { stringValue: expected_trace_id } }
      )
    end

    it 'includes pipeline duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |m| m[:name] == 'pipeline.duration_seconds' }

      aggregate_failures do
        expect(duration_metric).to be_present
        expect(duration_metric[:gauge][:dataPoints].first[:asDouble]).to eq(300.0)
        expect(duration_metric[:gauge][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'pipeline.status', value: { stringValue: 'success' } },
          { key: 'pipeline.ref', value: { stringValue: 'main' } }
        )
      end
    end

    it 'includes exemplars on pipeline duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |m| m[:name] == 'pipeline.duration_seconds' }
      exemplars = duration_metric[:gauge][:dataPoints].first[:exemplars]

      aggregate_failures do
        expect(exemplars).to be_present
        expect(exemplars.first[:traceId]).to eq(expected_trace_id)
        expect(exemplars.first[:spanId]).to eq(expected_pipeline_span_id)
      end
    end

    it 'includes cicd.pipeline.run.duration histogram metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      histogram = metrics.find { |m| m[:name] == 'cicd.pipeline.run.duration' }

      aggregate_failures do
        expect(histogram).to be_present
        expect(histogram[:unit]).to eq('s')
        expect(histogram[:histogram][:aggregationTemporality]).to eq('AGGREGATION_TEMPORALITY_DELTA')

        data_point = histogram[:histogram][:dataPoints].first
        expect(data_point[:count]).to eq(1)
        expect(data_point[:sum]).to be_within(0.001).of(300.0)
        expect(data_point[:explicitBounds]).to eq([1, 5, 10, 30, 60, 300, 600, 1800, 3600])
        expect(data_point[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } },
          { key: 'gitlab.cicd.pipeline.trigger.type', value: { stringValue: 'push' } },
          { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
        )
      end
    end

    it 'does not include cicd.pipeline.run.duration when duration is missing' do
      pipeline_data[:object_attributes].delete(:duration)
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      expect(metrics.find { |m| m[:name] == 'cicd.pipeline.run.duration' }).to be_nil
    end

    it 'includes pipeline status counter' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      status_metric = metrics.find { |m| m[:name] == 'pipeline.status_total' }

      aggregate_failures do
        expect(status_metric).to be_present
        expect(status_metric[:sum][:dataPoints].first[:asInt]).to eq(1)
        expect(status_metric[:sum][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'pipeline.status', value: { stringValue: 'success' } },
          { key: 'pipeline.ref', value: { stringValue: 'main' } }
        )
      end
    end

    it 'includes cicd.pipeline.run.count counter' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      run_count = metrics.find { |m| m[:name] == 'cicd.pipeline.run.count' }

      aggregate_failures do
        expect(run_count).to be_present
        expect(run_count[:unit]).to eq('1')
        expect(run_count[:sum][:isMonotonic]).to be(true)
        expect(run_count[:sum][:dataPoints].first[:asInt]).to eq(1)
        expect(run_count[:sum][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } },
          { key: 'gitlab.cicd.pipeline.trigger.type', value: { stringValue: 'push' } },
          { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
        )
      end
    end

    it 'includes job count gauge' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      count_metric = metrics.find { |m| m[:name] == 'pipeline.jobs_total' }

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

      task_total = metrics.find { |m| m[:name] == 'cicd.pipeline.task.total' }

      aggregate_failures do
        expect(task_total).to be_present
        expect(task_total[:unit]).to eq('1')
        expect(task_total[:gauge][:dataPoints].first[:asInt]).to eq(2)
        expect(task_total[:gauge][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } }
        )
      end
    end

    it 'includes job duration histogram' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |m| m[:name] == 'job.duration_seconds' }

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

      task_duration = metrics.find { |m| m[:name] == 'cicd.pipeline.task.duration' }

      aggregate_failures do
        expect(task_duration).to be_present
        expect(task_duration[:unit]).to eq('s')
        expect(task_duration[:histogram][:dataPoints].length).to eq(2)
        expect(task_duration[:histogram][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'cicd.pipeline.task.type', value: { stringValue: 'test' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } },
          { key: 'gitlab.cicd.pipeline.trigger.type', value: { stringValue: 'push' } },
          { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
        )
      end
    end

    it 'does not include cicd.pipeline.task.duration when builds are empty' do
      pipeline_data[:builds] = []
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      expect(metrics.find { |m| m[:name] == 'cicd.pipeline.task.duration' }).to be_nil
    end

    it 'includes queue duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      queue_metric = metrics.find { |m| m[:name] == 'pipeline.queue_duration_seconds' }

      aggregate_failures do
        expect(queue_metric).to be_present
        expect(queue_metric[:gauge][:dataPoints].first[:asDouble]).to eq(30.0)
        expect(queue_metric[:gauge][:dataPoints].first[:attributes]).to contain_exactly(
          { key: 'pipeline.status', value: { stringValue: 'success' } },
          { key: 'pipeline.ref', value: { stringValue: 'main' } }
        )
      end
    end

    it 'includes gitlab.cicd.pipeline.run.queued_duration metric' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      queue_duration = metrics.find { |m| m[:name] == 'gitlab.cicd.pipeline.run.queued_duration' }

      aggregate_failures do
        expect(queue_duration).to be_present
        expect(queue_duration[:unit]).to eq('s')
        expect(queue_duration[:gauge][:dataPoints].first[:asDouble]).to be_within(0.001).of(30.0)
        expect(queue_duration[:gauge][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } }
        )
      end
    end

    it 'does not include gitlab.cicd.pipeline.run.queued_duration when queued_duration is missing' do
      pipeline_data[:object_attributes].delete(:queued_duration)
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      expect(metrics.find { |m| m[:name] == 'gitlab.cicd.pipeline.run.queued_duration' }).to be_nil
    end

    it 'handles empty pipeline data' do
      converter = described_class.new(integration, {})
      result = converter.convert

      expect(result[:resourceMetrics]).to be_empty
    end

    it 'handles missing duration gracefully' do
      pipeline_data[:object_attributes].delete(:duration)
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      expect(metrics.find { |m| m[:name] == 'pipeline.duration_seconds' }).to be_nil
    end

    it 'handles missing builds gracefully' do
      pipeline_data[:builds] = []
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      expect(metrics.find { |m| m[:name] == 'job.duration_seconds' }).to be_nil
    end

    it 'builds histogram buckets correctly' do
      result = converter.convert
      metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

      duration_metric = metrics.find { |m| m[:name] == 'job.duration_seconds' }
      data_point = duration_metric[:histogram][:dataPoints].first

      aggregate_failures do
        expect(data_point[:count]).to eq(1)
        expect(data_point[:sum]).to eq(120000)
        expect(data_point[:bucketCounts]).to be_an(Array)
        expect(data_point[:explicitBounds]).to eq([1, 5, 10, 30, 60, 300, 600, 1800, 3600])
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

      it 'emits vcs.ref.head.type as tag in semconv attributes' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        run_count = metrics.find { |m| m[:name] == 'cicd.pipeline.run.count' }

        expect(run_count[:sum][:dataPoints].first[:attributes]).to include(
          { key: 'vcs.ref.head.type', value: { stringValue: 'tag' } }
        )
      end
    end

    context 'with pipeline result mapping' do
      it 'maps success to success' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]
        run_count = metrics.find { |m| m[:name] == 'cicd.pipeline.run.count' }

        expect(run_count[:sum][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.result', value: { stringValue: 'success' } }
        )
      end

      it 'maps failed to failure' do
        pipeline_data[:object_attributes][:status] = 'failed'
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]
        run_count = metrics.find { |m| m[:name] == 'cicd.pipeline.run.count' }

        expect(run_count[:sum][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.result', value: { stringValue: 'failure' } }
        )
      end

      it 'maps canceled to cancellation' do
        pipeline_data[:object_attributes][:status] = 'canceled'
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]
        run_count = metrics.find { |m| m[:name] == 'cicd.pipeline.run.count' }

        expect(run_count[:sum][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.result', value: { stringValue: 'cancellation' } }
        )
      end

      it 'falls back to raw status when no mapped result' do
        pipeline_data[:object_attributes][:status] = 'running'
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]
        run_count = metrics.find { |m| m[:name] == 'cicd.pipeline.run.count' }

        expect(run_count[:sum][:dataPoints].first[:attributes]).to include(
          { key: 'cicd.pipeline.result', value: { stringValue: 'running' } }
        )
      end
    end

    context 'when pipeline has failed' do
      before do
        pipeline_data[:object_attributes][:status] = 'failed'
      end

      it 'includes cicd.pipeline.run.errors metric' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        errors_metric = metrics.find { |m| m[:name] == 'cicd.pipeline.run.errors' }

        aggregate_failures do
          expect(errors_metric).to be_present
          expect(errors_metric[:unit]).to eq('{error}')
          expect(errors_metric[:sum][:isMonotonic]).to be(true)
          expect(errors_metric[:sum][:dataPoints].first[:asInt]).to eq(1)
          expect(errors_metric[:sum][:dataPoints].first[:attributes]).to contain_exactly(
            { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } },
            { key: 'error.type', value: { stringValue: '_OTHER' } }
          )
        end
      end
    end

    context 'when pipeline has succeeded' do
      it 'does not include cicd.pipeline.run.errors metric' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        expect(metrics.find { |m| m[:name] == 'cicd.pipeline.run.errors' }).to be_nil
      end
    end

    context 'when pipeline has bridge jobs' do
      let(:pipeline_data) do
        base_pipeline_data.deep_merge(
          object_attributes: { tag: false },
          bridges: [
            {
              id: 3,
              name: 'trigger-child',
              stage: 'trigger',
              status: 'success',
              started_at: Time.zone.parse('2023-01-01T10:03:30Z'),
              finished_at: Time.zone.parse('2023-01-01T10:04:30Z'),
              duration: 60000,
              queued_duration: 1000,
              manual: false,
              allow_failure: false,
              bridge: true
            }
          ]
        )
      end

      it 'includes bridge jobs in pipeline.jobs_total count' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        count_metric = metrics.find { |m| m[:name] == 'pipeline.jobs_total' }

        expect(count_metric[:gauge][:dataPoints].first[:asInt]).to eq(3)
      end

      it 'includes bridge jobs in cicd.pipeline.task.total count' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        task_total = metrics.find { |m| m[:name] == 'cicd.pipeline.task.total' }

        expect(task_total[:gauge][:dataPoints].first[:asInt]).to eq(3)
      end

      it 'includes bridge jobs in job.duration_seconds histogram' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        duration_metric = metrics.find { |m| m[:name] == 'job.duration_seconds' }
        stages = duration_metric[:histogram][:dataPoints].map do |dp|
          dp[:attributes].find { |a| a[:key] == 'job.stage' }[:value][:stringValue]
        end

        expect(stages).to include('trigger')
      end

      it 'includes bridge jobs in cicd.pipeline.task.duration histogram' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        task_duration = metrics.find { |m| m[:name] == 'cicd.pipeline.task.duration' }
        stages = task_duration[:histogram][:dataPoints].map do |dp|
          dp[:attributes].find { |a| a[:key] == 'cicd.pipeline.task.type' }[:value][:stringValue]
        end

        expect(stages).to include('trigger')
      end
    end

    context 'when pipeline source is nil' do
      let(:pipeline_data) do
        data = base_pipeline_data.deep_merge(object_attributes: { tag: false })
        data[:object_attributes].delete(:source)
        data
      end

      it 'omits gitlab.cicd.pipeline.trigger.type from semconv_pipeline_attributes' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        run_count = metrics.find { |m| m[:name] == 'cicd.pipeline.run.count' }
        attr_keys = run_count[:sum][:dataPoints].first[:attributes].map { |a| a[:key] }

        expect(attr_keys).not_to include('gitlab.cicd.pipeline.trigger.type')
      end

      it 'omits gitlab.cicd.pipeline.trigger.type from task duration histogram' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        task_duration = metrics.find { |m| m[:name] == 'cicd.pipeline.task.duration' }
        attr_keys = task_duration[:histogram][:dataPoints].first[:attributes].map { |a| a[:key] }

        expect(attr_keys).not_to include('gitlab.cicd.pipeline.trigger.type')
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

    context 'with trace context correlation' do
      it 'includes exemplars with valid traceId and spanId on data points' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        metrics.each do |metric|
          data_points = metric.dig(:sum, :dataPoints) ||
            metric.dig(:gauge, :dataPoints) ||
            metric.dig(:histogram, :dataPoints) || []

          data_points.each do |dp|
            next unless dp.key?(:exemplars)

            dp[:exemplars].each do |exemplar|
              aggregate_failures do
                expect(exemplar[:traceId]).to match(/\A[0-9a-f]{32}\z/)
                expect(exemplar[:spanId]).to match(/\A[0-9a-f]{16}\z/)
              end
            end
          end
        end
      end

      it 'sets exemplar traceId matching the pipeline trace ID' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        duration_metric = metrics.find { |m| m[:name] == 'pipeline.duration_seconds' }
        exemplar = duration_metric[:gauge][:dataPoints].first[:exemplars].first

        expect(exemplar[:traceId]).to eq(expected_trace_id)
      end

      it 'sets exemplar spanId matching the pipeline span ID' do
        result = converter.convert
        metrics = result[:resourceMetrics].first[:scopeMetrics].first[:metrics]

        duration_metric = metrics.find { |m| m[:name] == 'pipeline.duration_seconds' }
        exemplar = duration_metric[:gauge][:dataPoints].first[:exemplars].first

        expect(exemplar[:spanId]).to eq(expected_pipeline_span_id)
      end
    end
  end
end
