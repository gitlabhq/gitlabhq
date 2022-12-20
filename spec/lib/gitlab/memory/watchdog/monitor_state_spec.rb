# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Memory::Watchdog::MonitorState do
  let(:max_strikes) { 2 }
  let(:payload) { { message: 'DummyMessage' } }
  let(:threshold_violated) { true }
  let(:monitor) { monitor_class.new(threshold_violated, payload) }
  let(:monitor_name) { :dummy_monitor_name }
  let(:monitor_class) do
    Struct.new(:threshold_violated, :payload) do
      def call
        { threshold_violated: threshold_violated, payload: payload }
      end

      def self.name
        'MonitorName'
      end
    end
  end

  subject(:monitor_state) { described_class.new(monitor, max_strikes: max_strikes, monitor_name: monitor_name) }

  shared_examples 'returns correct result' do
    it 'returns correct result', :aggregate_failures do
      result = monitor_state.call

      expect(result).to be_an_instance_of(described_class::Result)
      expect(result.strikes_exceeded?).to eq(strikes_exceeded)
      expect(result.threshold_violated?).to eq(threshold_violated)
      expect(result.payload).to eq(expected_payload)
      expect(result.monitor_name).to eq(monitor_name)
    end
  end

  describe '#call' do
    let(:strikes_exceeded) { false }
    let(:curr_strikes) { 0 }
    let(:expected_payload) do
      {
        memwd_max_strikes: max_strikes,
        memwd_cur_strikes: curr_strikes
      }.merge(payload)
    end

    context 'when threshold is not violated' do
      let(:threshold_violated) { false }

      include_examples 'returns correct result'
    end

    context 'when threshold is violated' do
      let(:curr_strikes) { 1 }
      let(:threshold_violated) { true }

      include_examples 'returns correct result'

      context 'when strikes_exceeded' do
        let(:max_strikes) { 0 }
        let(:strikes_exceeded) { true }

        include_examples 'returns correct result'
      end
    end
  end
end
