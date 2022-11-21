# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Watchdog, :aggregate_failures do
  context 'watchdog' do
    let(:configuration) { instance_double(described_class::Configuration) }
    let(:handler) { instance_double(described_class::NullHandler) }
    let(:logger) { instance_double(::Logger) }
    let(:sleep_time_seconds) { 60 }
    let(:write_heap_dumps) { false }
    let(:threshold_violated) { false }
    let(:violations_counter) { instance_double(::Prometheus::Client::Counter) }
    let(:violations_handled_counter) { instance_double(::Prometheus::Client::Counter) }
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

    def stub_prometheus_metrics
      allow(Gitlab::Metrics).to receive(:counter)
        .with(:gitlab_memwd_violations_total, anything, anything)
        .and_return(violations_counter)
      allow(Gitlab::Metrics).to receive(:counter)
        .with(:gitlab_memwd_violations_handled_total, anything, anything)
        .and_return(violations_handled_counter)

      allow(violations_counter).to receive(:increment)
      allow(violations_handled_counter).to receive(:increment)
    end

    describe '#initialize' do
      it 'initialize new configuration' do
        expect(described_class::Configuration).to receive(:new)

        watchdog
      end
    end

    describe '#call' do
      before do
        stub_prometheus_metrics
        allow(Gitlab::Metrics::System).to receive(:memory_usage_rss).at_least(:once).and_return(
          total: 1024
        )
        allow(::Prometheus::PidProvider).to receive(:worker_id).and_return('worker_1')

        watchdog.configure do |config|
          config.handler = handler
          config.logger = logger
          config.sleep_time_seconds = sleep_time_seconds
          config.write_heap_dumps = write_heap_dumps
          config.monitors.push monitor_class, threshold_violated, payload, max_strikes: max_strikes
        end

        allow(handler).to receive(:call).and_return(true)
        allow(logger).to receive(:info)
        allow(logger).to receive(:warn)
      end

      it 'logs start message once' do
        expect(logger).to receive(:info).once
          .with(
            pid: Process.pid,
            worker_id: 'worker_1',
            memwd_handler_class: handler.class.name,
            memwd_sleep_time_s: sleep_time_seconds,
            memwd_rss_bytes: 1024,
            message: 'started')

        watchdog.call
      end

      it 'waits for check interval seconds' do
        expect(watchdog).to receive(:sleep).with(sleep_time_seconds)

        watchdog.call
      end

      context 'when gitlab_memory_watchdog ops toggle is off' do
        before do
          stub_feature_flags(gitlab_memory_watchdog: false)
        end

        it 'does not trigger any monitor' do
          expect(configuration).not_to receive(:monitors)
        end
      end

      context 'when process does not exceed threshold' do
        it 'does not increment violations counters' do
          expect(violations_counter).not_to receive(:increment)
          expect(violations_handled_counter).not_to receive(:increment)

          watchdog.call
        end

        it 'does not log violation' do
          expect(logger).not_to receive(:warn)

          watchdog.call
        end

        it 'does not execute handler' do
          expect(handler).not_to receive(:call)

          watchdog.call
        end
      end

      context 'when process exceeds threshold' do
        let(:threshold_violated) { true }

        it 'increments violations counter' do
          expect(violations_counter).to receive(:increment).with(reason: name)

          watchdog.call
        end

        context 'when process does not exceed the allowed number of strikes' do
          it 'does not increment handled violations counter' do
            expect(violations_handled_counter).not_to receive(:increment)

            watchdog.call
          end

          it 'does not log violation' do
            expect(logger).not_to receive(:warn)

            watchdog.call
          end

          it 'does not execute handler' do
            expect(handler).not_to receive(:call)

            watchdog.call
          end

          context 'and heap dumps are enabled' do
            let(:write_heap_dumps) { true }

            it 'does not schedule a heap dump' do
              expect(Gitlab::Memory::Reports::HeapDump).not_to receive(:enqueue!)

              watchdog.call
            end
          end
        end

        context 'when monitor exceeds the allowed number of strikes' do
          let(:max_strikes) { 0 }

          it 'increments handled violations counter' do
            expect(violations_handled_counter).to receive(:increment).with(reason: name)

            watchdog.call
          end

          it 'logs violation' do
            expect(logger).to receive(:warn)
              .with(
                pid: Process.pid,
                worker_id: 'worker_1',
                memwd_handler_class: handler.class.name,
                memwd_sleep_time_s: sleep_time_seconds,
                memwd_rss_bytes: 1024,
                memwd_cur_strikes: 1,
                memwd_max_strikes: max_strikes,
                message: 'dummy_text')

            watchdog.call
          end

          it 'executes handler' do
            expect(handler).to receive(:call)

            watchdog.call
          end

          context 'and heap dumps are enabled' do
            let(:write_heap_dumps) { true }

            it 'schedules a heap dump' do
              expect(Gitlab::Memory::Reports::HeapDump).to receive(:enqueue!)

              watchdog.call
            end
          end

          context 'when enforce_memory_watchdog ops toggle is off' do
            before do
              stub_feature_flags(enforce_memory_watchdog: false)
            end

            it 'always uses the NullHandler' do
              expect(handler).not_to receive(:call)
              expect(described_class::NullHandler.instance).to receive(:call).and_return(true)

              watchdog.call
            end
          end

          context 'when multiple monitors exceeds allowed number of strikes' do
            before do
              watchdog.configure do |config|
                config.handler = handler
                config.logger = logger
                config.sleep_time_seconds = sleep_time_seconds
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

      it 'logs stop message once' do
        expect(logger).to receive(:info).once
          .with(
            pid: Process.pid,
            worker_id: 'worker_1',
            memwd_handler_class: handler.class.name,
            memwd_sleep_time_s: sleep_time_seconds,
            memwd_rss_bytes: 1024,
            message: 'stopped')

        watchdog.call
      end
    end

    describe '#configure' do
      it 'yields block' do
        expect { |b| watchdog.configure(&b) }.to yield_control
      end
    end
  end

  context 'handlers' do
    context 'NullHandler' do
      subject(:handler) { described_class::NullHandler.instance }

      describe '#call' do
        it 'does nothing' do
          expect(handler.call).to be(false)
        end
      end
    end

    context 'TermProcessHandler' do
      subject(:handler) { described_class::TermProcessHandler.new(42) }

      describe '#call' do
        before do
          allow(Process).to receive(:kill)
        end

        it 'sends SIGTERM to the current process' do
          expect(Process).to receive(:kill).with(:TERM, 42)

          expect(handler.call).to be(true)
        end
      end
    end

    context 'PumaHandler' do
      # rubocop: disable RSpec/VerifiedDoubles
      # In tests, the Puma constant is not loaded so we cannot make this an instance_double.
      let(:puma_worker_handle_class) { double('Puma::Cluster::WorkerHandle') }
      let(:puma_worker_handle) { double('worker') }
      # rubocop: enable RSpec/VerifiedDoubles

      subject(:handler) { described_class::PumaHandler.new({}) }

      before do
        stub_const('::Puma::Cluster::WorkerHandle', puma_worker_handle_class)
        allow(puma_worker_handle_class).to receive(:new).and_return(puma_worker_handle)
        allow(puma_worker_handle).to receive(:term)
      end

      describe '#call' do
        it 'invokes orderly termination via Puma API' do
          expect(puma_worker_handle).to receive(:term)

          expect(handler.call).to be(true)
        end
      end
    end
  end
end
