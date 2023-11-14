# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Watchdog, :aggregate_failures, feature_category: :cloud_connector do
  context 'watchdog' do
    let(:configuration) { instance_double(described_class::Configuration) }
    let(:handler) { instance_double(described_class::Handlers::NullHandler) }
    let(:reporter) { instance_double(described_class::EventReporter) }
    let(:sleep_time_seconds) { 60 }
    let(:threshold_violated) { false }
    let(:watchdog_iterations) { 1 }
    let(:name) { :monitor_name }
    let(:payload) { { message: 'dummy_text' } }
    let(:max_strikes) { 2 }
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

    subject(:watchdog) do
      described_class.new.tap do |instance|
        # We need to defuse `sleep` and stop the internal loop after 1 iteration
        iterations = 0
        allow(instance).to receive(:sleep) do
          instance.stop if (iterations += 1) > watchdog_iterations
        end
      end
    end

    describe '#initialize' do
      it 'initialize new configuration' do
        expect(described_class::Configuration).to receive(:new)

        watchdog
      end
    end

    describe '#call' do
      before do
        watchdog.configure do |config|
          config.handler = handler
          config.event_reporter = reporter
          config.sleep_time_seconds = sleep_time_seconds
        end

        allow(handler).to receive(:call).and_return(true)
        allow(reporter).to receive(:started)
        allow(reporter).to receive(:stopped)
        allow(reporter).to receive(:threshold_violated)
        allow(reporter).to receive(:strikes_exceeded)
      end

      it 'reports started event once' do
        expect(reporter).to receive(:started).once
          .with({
            memwd_handler_class: handler.class.name,
            memwd_sleep_time_s: sleep_time_seconds
          })

        watchdog.call
      end

      it 'waits for check interval seconds' do
        expect(watchdog).to receive(:sleep).with(sleep_time_seconds)

        watchdog.call
      end

      context 'when no monitors are configured' do
        it 'reports stopped event once with correct reason' do
          expect(reporter).to receive(:stopped).once
            .with({
              memwd_handler_class: handler.class.name,
              memwd_sleep_time_s: sleep_time_seconds,
              memwd_reason: 'monitors are not configured'
            })

          watchdog.call
        end
      end

      context 'when monitors are configured' do
        before do
          watchdog.configure do |config|
            config.monitors.push monitor_class, threshold_violated, payload, max_strikes: max_strikes
          end
        end

        it 'reports stopped event once' do
          expect(reporter).to receive(:stopped).once
            .with({
              memwd_handler_class: handler.class.name,
              memwd_sleep_time_s: sleep_time_seconds,
              memwd_reason: 'background task stopped'
            })

          watchdog.call
        end

        context 'when process does not exceed threshold' do
          it 'does not report violations event' do
            expect(reporter).not_to receive(:threshold_violated)
            expect(reporter).not_to receive(:strikes_exceeded)

            watchdog.call
          end

          it 'does not execute handler' do
            expect(handler).not_to receive(:call)

            watchdog.call
          end
        end

        context 'when process exceeds threshold' do
          let(:threshold_violated) { true }

          it 'reports threshold violated event' do
            expect(reporter).to receive(:threshold_violated).with(name)

            watchdog.call
          end

          context 'when process does not exceed the allowed number of strikes' do
            it 'does not report strikes exceeded event' do
              expect(reporter).not_to receive(:strikes_exceeded)

              watchdog.call
            end

            it 'does not execute handler' do
              expect(handler).not_to receive(:call)

              watchdog.call
            end
          end

          context 'when monitor exceeds the allowed number of strikes' do
            let(:max_strikes) { 0 }

            it 'reports strikes exceeded event' do
              expect(reporter).to receive(:strikes_exceeded)
                .with(
                  name, {
                    memwd_handler_class: handler.class.name,
                    memwd_sleep_time_s: sleep_time_seconds,
                    memwd_cur_strikes: 1,
                    memwd_max_strikes: max_strikes,
                    message: "dummy_text"
                  })

              watchdog.call
            end

            it 'executes handler and stops the watchdog' do
              expect(handler).to receive(:call).and_return(true)
              expect(reporter).to receive(:stopped).once
                .with({
                  memwd_handler_class: handler.class.name,
                  memwd_sleep_time_s: sleep_time_seconds,
                  memwd_reason: 'successfully handled'
                })

              watchdog.call
            end

            it 'schedules a heap dump' do
              expect(Gitlab::Memory::Reports::HeapDump).to receive(:enqueue!)

              watchdog.call
            end

            context 'when multiple monitors exceeds allowed number of strikes' do
              before do
                watchdog.configure do |config|
                  config.monitors.push monitor_class, threshold_violated, payload, max_strikes: max_strikes
                  config.monitors.push monitor_class, threshold_violated, payload, max_strikes: max_strikes
                end
              end

              it 'only calls the handler once' do
                expect(handler).to receive(:call).once.and_return(true)

                watchdog.call
              end
            end
          end
        end
      end
    end

    describe '#configure' do
      it 'yields block' do
        expect { |b| watchdog.configure(&b) }.to yield_control
      end
    end
  end
end
