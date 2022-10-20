# frozen_string_literal: true

require 'fast_spec_helper'
require_relative './simple_check_shared'

RSpec.describe Gitlab::HealthChecks::MasterCheck do
  context 'when Puma runs in Clustered mode' do
    before do
      allow(Gitlab::Runtime).to receive(:puma_in_clustered_mode?).and_return(true)

      # We need to capture the read pipe here to stub out the non-blocking read.
      # The original implementation actually forked the test suite for a more
      # end-to-end test but that caused knock-on effects on other tests.
      @pipe_read, _ = described_class.register_master
    end

    after do
      described_class.finish_master
    end

    describe '.available?' do
      specify { expect(described_class.available?).to be true }
    end

    describe '.readiness' do
      context 'when no worker registered' do
        it 'succeeds' do
          expect(described_class.readiness.success).to be(true)
        end
      end

      context 'when worker registers itself' do
        context 'when reading from pipe succeeds' do
          it 'succeeds' do
            expect(@pipe_read).to receive(:read_nonblock) # rubocop: disable RSpec/InstanceVariable

            described_class.register_worker

            expect(described_class.readiness.success).to be(true)
          end
        end

        context 'when read pipe is open but not ready for reading' do
          it 'succeeds' do
            expect(@pipe_read).to receive(:read_nonblock).and_raise(IO::EAGAINWaitReadable) # rubocop: disable RSpec/InstanceVariable

            described_class.register_worker

            expect(described_class.readiness.success).to be(true)
          end
        end
      end

      context 'when master finishes early' do
        it 'fails' do
          described_class.finish_master

          expect(described_class.readiness.success).to be(false)
        end
      end
    end
  end

  # '.readiness' check is not invoked if '.available?' returns false
  context 'when Puma runs in Single mode' do
    before do
      allow(Gitlab::Runtime).to receive(:puma_in_clustered_mode?).and_return(false)
    end

    describe '.available?' do
      specify { expect(described_class.available?).to be false }
    end
  end
end
