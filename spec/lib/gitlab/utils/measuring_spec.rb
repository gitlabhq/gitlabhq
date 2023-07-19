# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::Measuring do
  describe '#with_measuring' do
    let(:base_log_data) { {} }
    let(:result) { "result" }

    before do
      allow(ActiveSupport::Logger).to receive(:logger_outputs_to?).with(described_class.logger, $stdout).and_return(false)
    end

    let(:measurement) { described_class.new(base_log_data) }

    subject do
      measurement.with_measuring { result }
    end

    it 'measures and logs data', :aggregate_failures do
      expect(measurement).to receive(:with_measure_time).and_call_original
      expect(measurement).to receive(:with_count_queries).and_call_original
      expect(measurement).to receive(:with_gc_stats).and_call_original

      expect(described_class.logger).to receive(:info).with(include(:gc_stats, :time_to_finish, :number_of_sql_calls, :memory_usage, :label))

      is_expected.to eq(result)
    end

    context 'with base_log_data provided' do
      let(:base_log_data) { { test: "data" } }

      it 'logs includes base data' do
        expect(described_class.logger).to receive(:info).with(include(:test, :gc_stats, :time_to_finish, :number_of_sql_calls, :memory_usage, :label))

        subject
      end
    end
  end
end
