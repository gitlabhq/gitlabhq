# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePing::InstrumentedPayload do
  let(:uuid) { "0000-0000-0000" }

  before do
    allow(ApplicationRecord.connection).to receive(:transaction_open?).and_return(false)
    allow(Gitlab::CurrentSettings).to receive(:uuid).and_return(uuid)
  end

  context 'when building service ping with values' do
    let(:metrics_key_paths) { %w[counts.boards uuid redis_hll_counters.search.i_search_total_monthly] }
    let(:expected_payload) do
      {
        counts: { boards: 0 },
        redis_hll_counters: { search: { i_search_total_monthly: 0 } },
        uuid: uuid
      }
    end

    it 'builds the service ping payload for the metrics key_paths' do
      expect(described_class.new(metrics_key_paths, :with_value).build).to eq(expected_payload)
    end
  end

  context 'when building service ping with instrumentations' do
    let(:metrics_key_paths) { %w[counts.boards uuid redis_hll_counters.search.i_search_total_monthly] }
    let(:expected_payload) do
      {
        counts: { boards: "SELECT COUNT(\"boards\".\"id\") FROM \"boards\"" },
        redis_hll_counters: { search: { i_search_total_monthly: 0 } },
        uuid: uuid
      }
    end

    it 'builds the service ping payload for the metrics key_paths' do
      expect(described_class.new(metrics_key_paths, :with_instrumentation).build).to eq(expected_payload)
    end
  end

  context 'when missing instrumentation class' do
    it 'returns empty hash' do
      expect(described_class.new(['counts.ci_triggers'], :with_instrumentation).build).to eq({})
      expect(described_class.new(['counts.ci_triggers'], :with_value).build).to eq({})
    end
  end

  context 'with broken metric definition file' do
    let(:key_path) { 'counts.broken_metric_definition_test' }
    let(:definitions) { [Gitlab::Usage::MetricDefinition.new(key_path, key_path: key_path)] }

    subject(:build_metric) { described_class.new([key_path], :with_value).build }

    before do
      allow(Gitlab::Usage::MetricDefinition).to receive(:with_instrumentation_class).and_return(definitions)
      allow_next_instance_of(Gitlab::Usage::Metric) do |instance|
        allow(instance).to receive(:with_value).and_raise(error)
      end
    end

    context 'when instrumentation class name is incorrect' do
      let(:error) { NameError.new("uninitialized constant Gitlab::Usage::Metrics::Instrumentations::IDontExists") }

      it 'tracks error and return fallback', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        expect(build_metric).to eql(counts: { broken_metric_definition_test: -1 })
      end
    end

    context 'when instrumentation class raises TypeError' do
      let(:error) { TypeError.new("nil can't be coerced into BigDecimal") }

      it 'tracks error and return fallback', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        expect(build_metric).to eql(counts: { broken_metric_definition_test: -1 })
      end
    end

    context 'when instrumentation class raises ArgumentError' do
      let(:error) { ArgumentError.new("wrong number of arguments (given 2, expected 0)") }

      it 'tracks error and return fallback', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        expect(build_metric).to eql(counts: { broken_metric_definition_test: -1 })
      end
    end

    context 'when instrumentation class raises StandardError' do
      let(:error) { StandardError.new("something went very wrong") }

      it 'tracks error and return fallback', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        expect(build_metric).to eql(counts: { broken_metric_definition_test: -1 })
      end
    end
  end
end
