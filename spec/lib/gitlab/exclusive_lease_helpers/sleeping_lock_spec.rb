# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExclusiveLeaseHelpers::SleepingLock, :clean_gitlab_redis_shared_state do
  include ::ExclusiveLeaseHelpers

  let(:timeout) { 1.second }
  let(:delay) { 0.1.seconds }
  let(:key) { SecureRandom.hex(10) }

  subject { described_class.new(key, timeout: timeout, delay: delay) }

  describe '#retried?' do
    before do
      stub_exclusive_lease(key, 'uuid')
    end

    context 'we have not made any attempts' do
      it { is_expected.not_to be_retried }
    end

    context 'we just made a single (initial) attempt' do
      it 'is not considered a retry' do
        subject.send(:try_obtain)

        is_expected.not_to be_retried
      end
    end

    context 'made multiple attempts' do
      it 'is considered a retry' do
        2.times { subject.send(:try_obtain) }

        is_expected.to be_retried
      end
    end
  end

  describe '#obtain' do
    context 'when the lease is not held' do
      before do
        stub_exclusive_lease(key, 'uuid')
      end

      it 'obtains the lease on the first attempt, without sleeping' do
        expect(subject).not_to receive(:sleep)

        subject.obtain(10)

        expect(subject).not_to be_retried
      end
    end

    context 'when the lease is obtained already' do
      let!(:lease) { stub_exclusive_lease_taken(key) }

      context 'when retries are not specified' do
        it 'retries to obtain a lease and raises an error' do
          expect(lease).to receive(:try_obtain).exactly(10).times

          expect { subject.obtain }.to raise_error('Failed to obtain a lock')
        end
      end

      context 'when specified retries are above the maximum attempts' do
        let(:max_attempts) { 100 }

        it 'retries to obtain a lease and raises an error' do
          expect(lease).to receive(:try_obtain).exactly(65).times

          expect { subject.obtain(max_attempts) }.to raise_error('Failed to obtain a lock')
        end
      end
    end

    context 'when the lease is held elsewhere' do
      let!(:lease) { stub_exclusive_lease_taken(key) }
      let(:max_attempts) { 7 }

      it 'retries to obtain a lease and raises an error' do
        expect(subject).to receive(:sleep).with(delay).exactly(max_attempts - 1).times
        expect(lease).to receive(:try_obtain).exactly(max_attempts).times

        expect { subject.obtain(max_attempts) }.to raise_error('Failed to obtain a lock')
      end

      context 'when the delay is computed from the attempt number' do
        let(:delay) { ->(n) { 3 * n } }

        it 'uses the computation to determine the sleep length' do
          expect(subject).to receive(:sleep).with(3).once
          expect(subject).to receive(:sleep).with(6).once
          expect(subject).to receive(:sleep).with(9).once
          expect(lease).to receive(:try_obtain).exactly(4).times

          expect { subject.obtain(4) }.to raise_error('Failed to obtain a lock')
        end
      end

      context 'when lease is granted after retry' do
        it 'knows that it retried' do
          expect(subject).to receive(:sleep).with(delay).exactly(3).times
          expect(lease).to receive(:try_obtain).exactly(3).times { nil }
          expect(lease).to receive(:try_obtain).once { 'obtained' }

          subject.obtain(max_attempts)

          expect(subject).to be_retried
        end
      end
    end

    describe 'cancel' do
      let!(:lease) { stub_exclusive_lease(key, 'uuid') }

      it 'cancels the lease' do
        expect(lease).to receive(:cancel)

        subject.cancel
      end
    end
  end
end
