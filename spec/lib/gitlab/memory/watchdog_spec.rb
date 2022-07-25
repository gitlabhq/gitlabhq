# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Watchdog, :aggregate_failures, :prometheus do
  context 'watchdog' do
    let(:logger) { instance_double(::Logger) }
    let(:handler) { instance_double(described_class::NullHandler) }

    let(:heap_frag_limit_gauge) { instance_double(::Prometheus::Client::Gauge) }
    let(:heap_frag_violations_counter) { instance_double(::Prometheus::Client::Counter) }
    let(:heap_frag_violations_handled_counter) { instance_double(::Prometheus::Client::Counter) }

    let(:sleep_time) { 0.1 }
    let(:max_heap_fragmentation) { 0.2 }

    subject(:watchdog) do
      described_class.new(handler: handler, logger: logger, sleep_time_seconds: sleep_time,
                          max_strikes: max_strikes, max_heap_fragmentation: max_heap_fragmentation)
    end

    before do
      allow(handler).to receive(:on_high_heap_fragmentation).and_return(true)

      allow(logger).to receive(:warn)
      allow(logger).to receive(:info)

      allow(Gitlab::Metrics::Memory).to receive(:gc_heap_fragmentation).and_return(fragmentation)

      allow(::Prometheus::PidProvider).to receive(:worker_id).and_return('worker_1')
    end

    after do
      watchdog.stop
    end

    context 'when starting up' do
      let(:fragmentation) { 0 }
      let(:max_strikes) { 0 }

      it 'sets the heap fragmentation limit gauge' do
        allow(Gitlab::Metrics).to receive(:gauge).with(anything, anything).and_return(heap_frag_limit_gauge)

        expect(heap_frag_limit_gauge).to receive(:set).with({}, max_heap_fragmentation)
      end

      context 'when no settings are set in the environment' do
        it 'initializes with defaults' do
          watchdog = described_class.new(handler: handler, logger: logger)

          expect(watchdog.max_heap_fragmentation).to eq(described_class::DEFAULT_HEAP_FRAG_THRESHOLD)
          expect(watchdog.max_strikes).to eq(described_class::DEFAULT_MAX_STRIKES)
          expect(watchdog.sleep_time_seconds).to eq(described_class::DEFAULT_SLEEP_TIME_SECONDS)
        end
      end

      context 'when settings are passed through the environment' do
        before do
          stub_env('GITLAB_MEMWD_MAX_HEAP_FRAG', 1)
          stub_env('GITLAB_MEMWD_MAX_STRIKES', 2)
          stub_env('GITLAB_MEMWD_SLEEP_TIME_SEC', 3)
        end

        it 'initializes with these settings' do
          watchdog = described_class.new(handler: handler, logger: logger)

          expect(watchdog.max_heap_fragmentation).to eq(1)
          expect(watchdog.max_strikes).to eq(2)
          expect(watchdog.sleep_time_seconds).to eq(3)
        end
      end
    end

    context 'when process does not exceed heap fragmentation threshold' do
      let(:fragmentation) { max_heap_fragmentation - 0.1 }
      let(:max_strikes) { 0 } # To rule out that we were granting too many strikes.

      it 'does not signal the handler' do
        expect(handler).not_to receive(:on_high_heap_fragmentation)

        watchdog.start

        sleep sleep_time * 3
      end
    end

    context 'when process exceeds heap fragmentation threshold permanently' do
      let(:fragmentation) { max_heap_fragmentation + 0.1 }

      before do
        expected_labels = { pid: 'worker_1' }
        allow(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_memwd_heap_frag_violations_total, anything, expected_labels)
          .and_return(heap_frag_violations_counter)
        allow(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_memwd_heap_frag_violations_handled_total, anything, expected_labels)
          .and_return(heap_frag_violations_handled_counter)
        allow(heap_frag_violations_counter).to receive(:increment)
        allow(heap_frag_violations_handled_counter).to receive(:increment)
      end

      context 'when process has not exceeded allowed number of strikes' do
        let(:max_strikes) { 10 }

        it 'does not signal the handler' do
          expect(handler).not_to receive(:on_high_heap_fragmentation)

          watchdog.start

          sleep sleep_time * 3
        end

        it 'does not log any events' do
          expect(logger).not_to receive(:warn)

          watchdog.start

          sleep sleep_time * 3
        end

        it 'increments the violations counter' do
          expect(heap_frag_violations_counter).to receive(:increment)

          watchdog.start

          sleep sleep_time * 3
        end

        it 'does not increment violations handled counter' do
          expect(heap_frag_violations_handled_counter).not_to receive(:increment)

          watchdog.start

          sleep sleep_time * 3
        end
      end

      context 'when process exceeds the allowed number of strikes' do
        let(:max_strikes) { 1 }

        it 'signals the handler and resets strike counter' do
          expect(handler).to receive(:on_high_heap_fragmentation).and_return(true)

          watchdog.start

          sleep sleep_time * 3

          expect(watchdog.strikes).to eq(0)
        end

        it 'logs the event' do
          expect(Gitlab::Metrics::System).to receive(:memory_usage_rss).at_least(:once).and_return(1024)
          expect(logger).to receive(:warn).with({
            message: 'heap fragmentation limit exceeded',
            pid: Process.pid,
            worker_id: 'worker_1',
            memwd_handler_class: 'RSpec::Mocks::InstanceVerifyingDouble',
            memwd_sleep_time_s: sleep_time,
            memwd_max_heap_frag: max_heap_fragmentation,
            memwd_cur_heap_frag: fragmentation,
            memwd_max_strikes: max_strikes,
            memwd_cur_strikes: max_strikes + 1,
            memwd_rss_bytes: 1024
          })

          watchdog.start

          sleep sleep_time * 3
        end

        it 'increments both the violations and violations handled counters' do
          expect(heap_frag_violations_counter).to receive(:increment)
          expect(heap_frag_violations_handled_counter).to receive(:increment)

          watchdog.start

          sleep sleep_time * 3
        end

        context 'when enforce_memory_watchdog ops toggle is off' do
          before do
            stub_feature_flags(enforce_memory_watchdog: false)
          end

          it 'always uses the NullHandler' do
            expect(handler).not_to receive(:on_high_heap_fragmentation)
            expect(described_class::NullHandler.instance).to(
              receive(:on_high_heap_fragmentation).with(fragmentation).and_return(true)
            )

            watchdog.start

            sleep sleep_time * 3
          end
        end
      end

      context 'when handler result is true' do
        let(:max_strikes) { 1 }

        it 'considers the event handled and stops itself' do
          expect(handler).to receive(:on_high_heap_fragmentation).once.and_return(true)

          watchdog.start

          sleep sleep_time * 3
        end
      end

      context 'when handler result is false' do
        let(:max_strikes) { 1 }

        it 'keeps running' do
          # Return true the third time to terminate the daemon.
          expect(handler).to receive(:on_high_heap_fragmentation).and_return(false, false, true)

          watchdog.start

          sleep sleep_time * 4
        end
      end
    end

    context 'when process exceeds heap fragmentation threshold temporarily' do
      let(:fragmentation) { max_heap_fragmentation }
      let(:max_strikes) { 1 }

      before do
        allow(Gitlab::Metrics::Memory).to receive(:gc_heap_fragmentation).and_return(
          fragmentation - 0.1,
          fragmentation + 0.2,
          fragmentation - 0.1,
          fragmentation + 0.1
        )
      end

      it 'does not signal the handler' do
        expect(handler).not_to receive(:on_high_heap_fragmentation)

        watchdog.start

        sleep sleep_time * 4
      end
    end

    context 'when gitlab_memory_watchdog ops toggle is off' do
      let(:fragmentation) { 0 }
      let(:max_strikes) { 0 }

      before do
        stub_feature_flags(gitlab_memory_watchdog: false)
      end

      it 'does not monitor heap fragmentation' do
        expect(Gitlab::Metrics::Memory).not_to receive(:gc_heap_fragmentation)

        watchdog.start

        sleep sleep_time * 3
      end
    end
  end

  context 'handlers' do
    context 'NullHandler' do
      subject(:handler) { described_class::NullHandler.instance }

      describe '#on_high_heap_fragmentation' do
        it 'does nothing' do
          expect(handler.on_high_heap_fragmentation(1.0)).to be(false)
        end
      end
    end

    context 'TermProcessHandler' do
      subject(:handler) { described_class::TermProcessHandler.new(42) }

      describe '#on_high_heap_fragmentation' do
        it 'sends SIGTERM to the current process' do
          expect(Process).to receive(:kill).with(:TERM, 42)

          expect(handler.on_high_heap_fragmentation(1.0)).to be(true)
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
      end

      describe '#on_high_heap_fragmentation' do
        it 'invokes orderly termination via Puma API' do
          expect(puma_worker_handle_class).to receive(:new).and_return(puma_worker_handle)
          expect(puma_worker_handle).to receive(:term)

          expect(handler.on_high_heap_fragmentation(1.0)).to be(true)
        end
      end
    end
  end
end
