# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::AggregationEngineSlis, feature_category: :value_stream_management do
  let(:engine) { Class.new.new }
  let(:labels) { { engine: 'unknown', query_type: 'data', feature_category: 'value_stream_management' } }
  let(:apdex) { Gitlab::Metrics::Sli::Apdex[:aggregation_engine_query] }
  let(:error_rate) { Gitlab::Metrics::Sli::ErrorRate[:aggregation_engine_query] }
  let(:histogram) { instance_double(Prometheus::Client::Histogram, observe: nil) }

  before do
    allow(Gitlab::Metrics).to receive(:histogram).and_call_original
    allow(Gitlab::Metrics).to receive(:histogram)
      .with(:gitlab_aggregation_engine_query_duration_seconds, anything, anything, anything)
      .and_return(histogram)
  end

  describe '.initialize_slis!' do
    it 'initializes both SLIs without pre-defined label combinations', :aggregate_failures do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(:aggregation_engine_query, [])
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(:aggregation_engine_query, [])

      described_class.initialize_slis!
    end
  end

  describe '.measure' do
    def measure(duration_s: 1, &block)
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(10, 10 + duration_s)

      described_class.measure(engine: engine, query_type: :data, &block)
    end

    it 'returns the block value and records a successful query', :aggregate_failures do
      expect(histogram).to receive(:observe).with(labels, 1)
      expect(error_rate).to receive(:increment).with(labels: labels, error: false)
      expect(apdex).to receive(:increment).with(labels: labels, success: true)

      expect(measure { :rows }).to eq(:rows)
    end

    context 'when the engine is a named class' do
      let(:engine) { stub_const('Analytics::AggregationEngines::MergeRequests', Class.new).new }

      it 'labels the query with the engine name' do
        expect(error_rate).to receive(:increment)
          .with(labels: labels.merge(engine: 'merge_requests'), error: false)

        measure { :rows }
      end
    end

    context 'when the query takes longer than the target' do
      it 'records an apdex failure' do
        expect(apdex).to receive(:increment).with(labels: labels, success: false)

        measure(duration_s: described_class::DEFAULT_TARGET_S + 0.1) { :rows }
      end
    end

    context 'when the query takes exactly the target' do
      it 'records an apdex failure, like the rails_request apdex' do
        expect(apdex).to receive(:increment).with(labels: labels, success: false)

        measure(duration_s: described_class::DEFAULT_TARGET_S) { :rows }
      end
    end

    context 'when the engine has its own target' do
      before do
        stub_const("#{described_class}::ENGINE_TARGETS_S", { 'unknown' => 0.5 })
      end

      it 'scores the query against that target' do
        expect(apdex).to receive(:increment).with(labels: labels, success: false)

        measure(duration_s: 1) { :rows }
      end
    end

    context 'when the query raises' do
      it 'records an error, skips apdex, and re-raises', :aggregate_failures do
        expect(histogram).to receive(:observe).with(labels, 1)
        expect(error_rate).to receive(:increment).with(labels: labels, error: true)
        expect(apdex).not_to receive(:increment)

        expect { measure { raise ArgumentError, 'boom' } }.to raise_error(ArgumentError, 'boom')
      end
    end

    context 'when the query is aborted by a non-StandardError' do
      it 'records an error and skips apdex', :aggregate_failures do
        expect(error_rate).to receive(:increment).with(labels: labels, error: true)
        expect(apdex).not_to receive(:increment)

        expect { measure { raise Interrupt } }.to raise_error(Interrupt)
      end
    end
  end
end
