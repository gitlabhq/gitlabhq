# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'gitlab/cluster/lifecycle_events'

RSpec.describe Gitlab::Memory::Watchdog::Configuration do
  subject(:configuration) { described_class.new }

  describe '#initialize' do
    it 'initialize monitors' do
      expect(configuration.monitors).to be_an_instance_of(described_class::MonitorStack)
    end
  end

  describe '#handler' do
    context 'when handler is not set' do
      it 'defaults to NullHandler' do
        expect(configuration.handler).to be(Gitlab::Memory::Watchdog::Handlers::NullHandler.instance)
      end
    end
  end

  describe '#event_reporter' do
    context 'when event reporter is not set' do
      before do
        allow(Gitlab::Metrics).to receive(:counter)
      end

      it 'defaults to EventReporter' do
        expect(configuration.event_reporter).to be_an_instance_of(::Gitlab::Memory::Watchdog::EventReporter)
      end
    end
  end

  describe '#sleep_time_seconds' do
    context 'when sleep_time_seconds is not set' do
      it 'defaults to SLEEP_TIME_SECONDS' do
        expect(configuration.sleep_time_seconds).to eq(described_class::DEFAULT_SLEEP_TIME_SECONDS)
      end
    end
  end

  describe '#monitors' do
    context 'when monitors are configured to be used' do
      let(:monitor_name1) { :monitor1 }
      let(:monitor_name2) { :monitor2 }
      let(:payload1) do
        {
          message: 'monitor_1_text',
          memwd_max_strikes: 5,
          memwd_cur_strikes: 0
        }
      end

      let(:payload2) do
        {
          message: 'monitor_2_text',
          memwd_max_strikes: 0,
          memwd_cur_strikes: 1
        }
      end

      let(:monitor_class_1) do
        Struct.new(:threshold_violated, :payload) do
          def call
            { threshold_violated: !!threshold_violated, payload: payload || {} }
          end

          def self.name
            'Monitor1'
          end
        end
      end

      let(:monitor_class_2) do
        Struct.new(:threshold_violated, :payload) do
          def call
            { threshold_violated: !!threshold_violated, payload: payload || {} }
          end

          def self.name
            'Monitor2'
          end
        end
      end

      context 'when two different monitor class are configured' do
        shared_examples 'executes monitors and returns correct results' do
          it 'calls each monitor and returns correct results', :aggregate_failures do
            payloads = []
            thresholds = []
            strikes = []
            monitor_names = []

            configuration.monitors.call_each do |result|
              payloads << result.payload
              thresholds << result.threshold_violated?
              strikes << result.strikes_exceeded?
              monitor_names << result.monitor_name
            end

            expect(payloads).to eq([payload1, payload2])
            expect(thresholds).to eq([false, true])
            expect(strikes).to eq([false, true])
            expect(monitor_names).to eq([monitor_name1, monitor_name2])
          end

          it 'monitors are not empty' do
            expect(configuration.monitors).not_to be_empty
          end
        end

        context 'when monitors are not configured' do
          it 'monitors are empty' do
            expect(configuration.monitors).to be_empty
          end
        end

        context 'when monitors are configured inline' do
          before do
            configuration.monitors.push monitor_class_1, false, { message: 'monitor_1_text' }, max_strikes: 5
            configuration.monitors.push monitor_class_2, true, { message: 'monitor_2_text' }, max_strikes: 0
          end

          include_examples 'executes monitors and returns correct results'
        end

        context 'when monitors are configured in a block' do
          before do
            configuration.monitors do |stack|
              stack.push monitor_class_1, false, { message: 'monitor_1_text' }, max_strikes: 5
              stack.push monitor_class_2, true, { message: 'monitor_2_text' }, max_strikes: 0
            end
          end

          include_examples 'executes monitors and returns correct results'
        end

        context 'when monitors are configured with monitor name' do
          let(:monitor_name1) { :mon_one }
          let(:monitor_name2) { :mon_two }

          before do
            configuration.monitors do |stack|
              stack.push monitor_class_1, false, { message: 'monitor_1_text' }, max_strikes: 5, monitor_name: :mon_one
              stack.push monitor_class_2, true, { message: 'monitor_2_text' }, max_strikes: 0, monitor_name: :mon_two
            end
          end

          include_examples 'executes monitors and returns correct results'
        end
      end
    end
  end
end
