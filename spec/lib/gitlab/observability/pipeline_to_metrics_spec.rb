# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../lib/gitlab/ci/trace_context'
require_relative '../../../support/shared_contexts/lib/gitlab/observability/pipeline_converter_shared_context'

RSpec.describe Gitlab::Observability::PipelineToMetrics, feature_category: :observability do
  using RSpec::Parameterized::TableSyntax

  include_context 'with pipeline converter data'

  let(:pipeline_data) { base_pipeline_data.deep_merge(object_attributes: { tag: false }) }
  let(:converter) { described_class.new(integration, pipeline_data) }

  let(:result) { converter.convert }
  let(:resource_attributes) { result[:resourceMetrics].first[:resource][:attributes] }
  let(:metrics) { result[:resourceMetrics].first[:scopeMetrics].first[:metrics] }

  let(:legacy_attributes) do
    [
      { key: 'pipeline.status', value: { stringValue: 'success' } },
      { key: 'pipeline.ref', value: { stringValue: 'main' } }
    ]
  end

  let(:semconv_attributes) do
    [
      { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } },
      { key: 'cicd.pipeline.run.state', value: { stringValue: 'finalizing' } },
      { key: 'cicd.pipeline.result', value: { stringValue: 'success' } },
      { key: 'gitlab.cicd.pipeline.trigger.type', value: { stringValue: 'push' } },
      { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
    ]
  end

  def metric(name)
    metrics.find { |m| m[:name] == name }
  end

  def data_points(name)
    m = metric(name)
    (m[:gauge] || m[:sum] || m[:histogram])[:dataPoints]
  end

  def data_point(name)
    data_points(name).first
  end

  def attribute_value(attributes, key)
    attributes.find { |a| a[:key] == key }&.dig(:value, :stringValue)
  end

  describe '#convert' do
    it 'returns a single OTLP resource metrics entry' do
      expect(result[:resourceMetrics]).to match([a_hash_including(:resource, :scopeMetrics)])
    end

    it 'returns an empty payload for empty pipeline data' do
      expect(described_class.new(integration, {}).convert[:resourceMetrics]).to be_empty
    end

    it 'includes resource attributes' do
      expect(resource_attributes).to include(
        { key: 'service.name', value: { stringValue: 'gitlab-ci' } },
        { key: 'vcs.provider.name', value: { stringValue: 'gitlab' } },
        { key: 'vcs.repository.name', value: { stringValue: 'test-project' } },
        { key: 'vcs.owner.name', value: { stringValue: 'test-org' } },
        { key: 'gitlab.cicd.pipeline.trace_id', value: { stringValue: expected_trace_id } }
      )
    end

    describe 'integration overrides' do
      where(:field, :attribute_key, :value) do
        :service_name | 'service.name'           | 'custom-service'
        :environment  | 'deployment.environment' | 'staging'
      end

      with_them do
        it 'uses the integration value' do
          integration.public_send(:"#{field}=", value)

          expect(resource_attributes).to include({ key: attribute_key, value: { stringValue: value } })
        end
      end
    end

    describe 'single-value metrics' do
      where(:name, :type, :unit, :value_key, :value, :attribute_set) do
        'pipeline.duration_seconds'                | :gauge | 's' | :asDouble | 300.0 | :legacy
        'pipeline.queue_duration_seconds'          | :gauge | 's' | :asDouble | 30.0  | :legacy
        'gitlab.cicd.pipeline.run.queued_duration' | :gauge | 's' | :asDouble | 30.0  | :semconv
        'pipeline.status_total'                    | :sum   | '1' | :asInt    | 1     | :legacy
        'cicd.pipeline.run.count'                  | :sum   | '1' | :asInt    | 1     | :semconv
        'pipeline.jobs_total'                      | :gauge | '1' | :asInt    | 2     | :legacy
        'cicd.pipeline.task.total'                 | :gauge | '1' | :asInt    | 2     | :semconv
      end

      with_them do
        it 'emits the metric with the expected type, unit, value and attributes' do
          aggregate_failures do
            expect(metric(name)).to include(unit: unit, type => be_present)
            expect(data_point(name)[value_key]).to eq(value)

            if attribute_set == :legacy
              expect(data_point(name)[:attributes]).to match_array(legacy_attributes)
            else
              expect(data_point(name)[:attributes]).to include(*semconv_attributes)
            end
          end
        end
      end
    end

    it 'marks counters as monotonic' do
      expect(metric('cicd.pipeline.run.count')[:sum][:isMonotonic]).to be(true)
    end

    it 'includes an exemplar linking pipeline.duration_seconds to the pipeline span' do
      expect(data_point('pipeline.duration_seconds')[:exemplars]).to contain_exactly(
        a_hash_including(traceId: expected_trace_id, spanId: expected_pipeline_span_id)
      )
    end

    it 'emits well-formed trace and span IDs on every exemplar' do
      exemplars = metrics.flat_map { |m| data_points(m[:name]) }.flat_map { |dp| dp[:exemplars] || [] }

      aggregate_failures do
        expect(exemplars).to be_present
        expect(exemplars).to all(a_hash_including(traceId: /\A\h{32}\z/, spanId: /\A\h{16}\z/))
      end
    end

    it 'emits cicd.pipeline.run.duration as a delta histogram' do
      histogram = metric('cicd.pipeline.run.duration')

      aggregate_failures do
        expect(histogram).to include(unit: 's')
        expect(histogram[:histogram][:aggregationTemporality]).to eq('AGGREGATION_TEMPORALITY_DELTA')
        expect(data_point('cicd.pipeline.run.duration')).to include(
          count: 1,
          sum: 300.0,
          explicitBounds: described_class::HISTOGRAM_BUCKETS
        )
        expect(data_point('cicd.pipeline.run.duration')[:attributes]).to include(*semconv_attributes)
      end
    end

    describe 'per-stage job duration histograms' do
      where(:name, :stage_key, :first_attributes) do
        [
          [
            'job.duration_seconds', 'job.stage',
            [
              { key: 'job.stage', value: { stringValue: 'test' } },
              { key: 'pipeline.status', value: { stringValue: 'success' } }
            ]
          ],
          [
            'cicd.pipeline.task.duration', 'cicd.pipeline.task.type',
            [
              { key: 'cicd.pipeline.task.type', value: { stringValue: 'test' } },
              { key: 'cicd.pipeline.result', value: { stringValue: 'success' } },
              { key: 'gitlab.cicd.pipeline.trigger.type', value: { stringValue: 'push' } },
              { key: 'vcs.ref.head.type', value: { stringValue: 'branch' } }
            ]
          ]
        ]
      end

      with_them do
        it 'emits one data point per stage, in seconds' do
          aggregate_failures do
            expect(metric(name)).to include(unit: 's')
            expect(data_points(name).length).to eq(2)
            expect(data_point(name)).to include(count: 1, sum: 120)
            expect(data_point(name)[:attributes]).to match_array(first_attributes)
          end
        end

        context 'when the pipeline has bridge jobs' do
          before do
            pipeline_data[:bridges] = [
              { id: 3, name: 'trigger-child', stage: 'trigger', status: 'success', duration: 60, bridge: true }
            ]
          end

          it 'includes the bridge stage' do
            stages = data_points(name).map { |dp| attribute_value(dp[:attributes], stage_key) }

            expect(stages).to include('trigger')
          end
        end
      end
    end

    context 'when the pipeline has bridge jobs' do
      before do
        pipeline_data[:bridges] = [{ id: 3, name: 'trigger-child', stage: 'trigger', bridge: true }]
      end

      where(name: %w[pipeline.jobs_total cicd.pipeline.task.total])

      with_them do
        it 'counts bridges as jobs' do
          expect(data_point(name)[:asInt]).to eq(3)
        end
      end
    end

    describe 'histogram bucket boundaries' do
      where(:duration, :expected_index) do
        0.5  | 0
        1    | 0
        1.5  | 1
        60   | 4
        60.1 | 5
        300  | 5
        3600 | 8
        3601 | 9
      end

      with_them do
        before do
          pipeline_data[:builds] = [pipeline_data[:builds].first.merge(duration: duration)]
        end

        it 'places the duration (in seconds) in the expected bucket' do
          expected = Array.new(described_class::HISTOGRAM_BUCKETS.length + 1, 0)
          expected[expected_index] = 1

          expect(data_point('job.duration_seconds')[:bucketCounts]).to eq(expected)
        end
      end
    end

    describe 'conditionally omitted metrics' do
      where(:scenario, :omitted) do
        [
          [:missing_duration, %w[pipeline.duration_seconds cicd.pipeline.run.duration]],
          [:missing_queued_duration, %w[pipeline.queue_duration_seconds gitlab.cicd.pipeline.run.queued_duration]],
          [:no_builds, %w[job.duration_seconds cicd.pipeline.task.duration]],
          [:succeeded, %w[cicd.pipeline.run.errors]]
        ]
      end

      with_them do
        before do
          case scenario
          when :missing_duration then pipeline_data[:object_attributes].delete(:duration)
          when :missing_queued_duration then pipeline_data[:object_attributes].delete(:queued_duration)
          when :no_builds then pipeline_data[:builds] = []
          end
        end

        it 'omits the metrics' do
          expect(metrics.pluck(:name)).not_to include(*omitted)
        end
      end
    end

    context 'when the pipeline has failed' do
      before do
        pipeline_data[:object_attributes][:status] = 'failed'
      end

      it 'emits cicd.pipeline.run.errors' do
        aggregate_failures do
          expect(metric('cicd.pipeline.run.errors')).to include(unit: '{error}')
          expect(metric('cicd.pipeline.run.errors')[:sum][:isMonotonic]).to be(true)
          expect(data_point('cicd.pipeline.run.errors')[:asInt]).to eq(1)
          expect(data_point('cicd.pipeline.run.errors')[:attributes]).to contain_exactly(
            { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } },
            { key: 'error.type', value: { stringValue: '_OTHER' } }
          )
        end
      end
    end

    describe 'cicd.pipeline.result mapping' do
      where(:status, :expected_result) do
        'success'  | 'success'
        'failed'   | 'failure'
        'canceled' | 'cancellation'
        'skipped'  | 'skip'
        'running'  | 'running'
      end

      with_them do
        before do
          pipeline_data[:object_attributes][:status] = status
        end

        it 'maps the pipeline status' do
          attributes = data_point('cicd.pipeline.run.count')[:attributes]

          expect(attribute_value(attributes, 'cicd.pipeline.result')).to eq(expected_result)
        end
      end
    end

    context 'when the pipeline is for a tag' do
      before do
        pipeline_data[:object_attributes][:tag] = true
      end

      it 'sets vcs.ref.head.type to tag' do
        expect(attribute_value(data_point('cicd.pipeline.run.count')[:attributes], 'vcs.ref.head.type')).to eq('tag')
      end
    end

    context 'when the pipeline source is nil' do
      before do
        pipeline_data[:object_attributes].delete(:source)
      end

      where(name: %w[cicd.pipeline.run.count cicd.pipeline.task.duration])

      with_them do
        it 'omits gitlab.cicd.pipeline.trigger.type' do
          expect(data_point(name)[:attributes].pluck(:key)).not_to include('gitlab.cicd.pipeline.trigger.type')
        end
      end
    end

    it 'does not emit duplicate semconv metric names' do
      semconv_names = metrics.pluck(:name).grep(/\Acicd\./)

      expect(semconv_names).to eq(semconv_names.uniq)
    end
  end
end
