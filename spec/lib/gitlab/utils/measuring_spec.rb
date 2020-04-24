# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Utils::Measuring do
  describe '.execute_with' do
    let(:measurement_logger) { double(:logger) }
    let(:base_log_data) do
      {
        class: described_class.name
      }
    end
    let(:result_block) { 'result' }

    subject { described_class.execute_with(measurement_enabled, measurement_logger, base_log_data) { result_block } }

    context 'when measurement is enabled' do
      let(:measurement_enabled) { true }
      let!(:measurement) { described_class.new(logger: measurement_logger, base_log_data: base_log_data) }

      before do
        allow(measurement_logger).to receive(:info)
      end

      it 'measure execution with Gitlab::Utils::Measuring instance', :aggregate_failure do
        expect(described_class).to receive(:new).with(logger: measurement_logger, base_log_data: base_log_data) { measurement }
        expect(measurement).to receive(:with_measuring)

        subject
      end

      it 'returns result from yielded block' do
        is_expected.to eq(result_block)
      end
    end

    context 'when measurement is disabled' do
      let(:measurement_enabled) { false }

      it 'does not measure service execution' do
        expect(Gitlab::Utils::Measuring).not_to receive(:new)

        subject
      end

      it 'returns result from yielded block' do
        is_expected.to eq(result_block)
      end
    end
  end

  describe '#with_measuring' do
    let(:logger) { double(:logger) }
    let(:base_log_data) { {} }
    let(:result) { "result" }

    before do
      allow(logger).to receive(:info)
    end

    let(:measurement) { described_class.new(logger: logger, base_log_data: base_log_data) }

    subject do
      measurement.with_measuring { result }
    end

    it 'measures and logs data', :aggregate_failure do
      expect(measurement).to receive(:with_measure_time).and_call_original
      expect(measurement).to receive(:with_count_queries).and_call_original
      expect(measurement).to receive(:with_gc_stats).and_call_original

      expect(logger).to receive(:info).with(including(:gc_stats, :time_to_finish, :number_of_sql_calls, :memory_usage, :label))

      is_expected.to eq(result)
    end

    context 'with base_log_data provided' do
      let(:base_log_data) { { test: "data" } }

      it 'logs includes base data' do
        expect(logger).to receive(:info).with(including(:test, :gc_stats, :time_to_finish, :number_of_sql_calls, :memory_usage, :label))

        subject
      end
    end
  end
end
