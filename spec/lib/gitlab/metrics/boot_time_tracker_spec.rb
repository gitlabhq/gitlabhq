# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::BootTimeTracker, feature_category: :observability do
  let(:logger) { double('logger') }
  let(:gauge) { double('gauge') }
  let(:counter) { double('counter') }

  subject(:tracker) { described_class.instance }

  before do
    described_class.instance.reset!
    Gitlab::BootsnapCacheStore.reset!

    allow(logger).to receive(:info)
    allow(gauge).to receive(:set)
    allow(counter).to receive(:increment)
    allow(Gitlab::Metrics).to receive_messages(gauge: gauge, counter: counter)
  end

  after do
    Gitlab::BootsnapCacheStore.reset!
  end

  describe '#track_boot_time!' do
    described_class::SUPPORTED_RUNTIMES.each do |runtime|
      context "when called on #{runtime} for the first time" do
        before do
          expect(Gitlab::Runtime).to receive(:safe_identify).and_return(runtime)
        end

        it 'set the startup_time' do
          tracker.track_boot_time!(logger: logger)

          expect(tracker.startup_time).to be > 0
        end

        it 'records the current process runtime' do
          expect(Gitlab::Metrics::System).to receive(:process_runtime_elapsed_seconds).once

          tracker.track_boot_time!(logger: logger)
        end

        it 'logs the application boot time' do
          expect(Gitlab::Metrics::System).to receive(:process_runtime_elapsed_seconds).and_return(42)
          expect(logger).to receive(:info).with(message: 'Application boot finished', runtime: runtime.to_s, duration_s: 42)

          tracker.track_boot_time!(logger: logger)
        end

        it 'tracks boot time in a prometheus gauge' do
          expect(Gitlab::Metrics::System).to receive(:process_runtime_elapsed_seconds).and_return(42)
          expect(gauge).to receive(:set).with({}, 42)

          tracker.track_boot_time!(logger: logger)
        end

        context 'on subsequent calls' do
          it 'does nothing' do
            tracker.track_boot_time!(logger: logger)

            expect(Gitlab::Metrics::System).not_to receive(:process_runtime_elapsed_seconds)
            expect(logger).not_to receive(:info)
            expect(gauge).not_to receive(:set)

            tracker.track_boot_time!(logger: logger)
          end
        end
      end
    end

    context 'when Bootsnap instrumentation is enabled' do
      before do
        allow(Gitlab::Runtime).to receive(:safe_identify).and_return(:puma)
        allow(Gitlab::Metrics::System).to receive(:process_runtime_elapsed_seconds).and_return(42)

        Gitlab::BootsnapCacheStore.enable!
        Gitlab::BootsnapCacheStore.increment(:hit)
        Gitlab::BootsnapCacheStore.increment(:revalidated)
        Gitlab::BootsnapCacheStore.increment(:miss)
        Gitlab::BootsnapCacheStore.increment(:stale)
      end

      it 'logs the compile cache hit rate (as a percentage) alongside the boot time' do
        expect(logger).to receive(:info).with(
          message: 'Application boot finished',
          runtime: 'puma',
          duration_s: 42,
          'bootsnap.hit': 1,
          'bootsnap.revalidated': 1,
          'bootsnap.miss': 1,
          'bootsnap.stale': 1,
          'bootsnap.hit_ratio': 50
        )

        tracker.track_boot_time!(logger: logger)
      end

      it 'exposes the compile cache event counts as a counter' do
        expect(counter).to receive(:increment).with({ event: 'hit' }, 1)
        expect(counter).to receive(:increment).with({ event: 'revalidated' }, 1)
        expect(counter).to receive(:increment).with({ event: 'miss' }, 1)
        expect(counter).to receive(:increment).with({ event: 'stale' }, 1)

        tracker.track_boot_time!(logger: logger)
      end
    end

    context 'when Bootsnap instrumentation is enabled but no events were recorded' do
      before do
        allow(Gitlab::Runtime).to receive(:safe_identify).and_return(:puma)
        allow(Gitlab::Metrics::System).to receive(:process_runtime_elapsed_seconds).and_return(42)

        Gitlab::BootsnapCacheStore.enable!
      end

      it 'logs a nil hit ratio without raising' do
        expect(logger).to receive(:info).with(
          message: 'Application boot finished',
          runtime: 'puma',
          duration_s: 42,
          'bootsnap.hit': 0,
          'bootsnap.revalidated': 0,
          'bootsnap.miss': 0,
          'bootsnap.stale': 0,
          'bootsnap.hit_ratio': nil
        )

        expect { tracker.track_boot_time!(logger: logger) }.not_to raise_error
      end
    end

    context 'when Bootsnap instrumentation is disabled' do
      before do
        allow(Gitlab::Runtime).to receive(:safe_identify).and_return(:puma)
        allow(Gitlab::Metrics::System).to receive(:process_runtime_elapsed_seconds).and_return(42)
      end

      it 'does not add compile cache fields to the boot log' do
        expect(logger).to receive(:info).with(message: 'Application boot finished', runtime: 'puma', duration_s: 42)

        tracker.track_boot_time!(logger: logger)
      end
    end

    context 'when called on other runtimes' do
      it 'does nothing' do
        tracker.track_boot_time!(logger: logger)

        expect(Gitlab::Metrics::System).not_to receive(:process_runtime_elapsed_seconds)
        expect(logger).not_to receive(:info)
        expect(gauge).not_to receive(:set)

        tracker.track_boot_time!(logger: logger)
      end
    end
  end

  describe '#startup_time' do
    it 'returns 0 when boot time not tracked' do
      expect(tracker.startup_time).to eq(0)
    end
  end
end
