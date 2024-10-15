# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::BootTimeTracker, feature_category: :observability do
  let(:logger) { double('logger') }
  let(:gauge) { double('gauge') }

  subject(:tracker) { described_class.instance }

  before do
    described_class.instance.reset!

    allow(logger).to receive(:info)
    allow(gauge).to receive(:set)
    allow(Gitlab::Metrics).to receive(:gauge).and_return(gauge)
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
