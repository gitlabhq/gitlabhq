# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExclusiveLeaseHelpers, :clean_gitlab_redis_shared_state do
  include ::ExclusiveLeaseHelpers

  let(:class_instance) { (Class.new { include ::Gitlab::ExclusiveLeaseHelpers }).new }
  let(:unique_key) { SecureRandom.hex(10) }

  describe '#in_lock' do
    subject { class_instance.in_lock(unique_key, **options) {} }

    let(:options) { {} }

    context 'when unique key is not set' do
      let(:unique_key) {}

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'when the lease is not obtained yet' do
      let!(:lease) { stub_exclusive_lease(unique_key, 'uuid') }

      it 'calls the given block' do
        expect { |b| class_instance.in_lock(unique_key, &b) }
          .to yield_with_args(false, an_instance_of(described_class::SleepingLock))
      end

      it 'calls the given block continuously' do
        expect { |b| class_instance.in_lock(unique_key, &b) }
          .to yield_with_args(false, an_instance_of(described_class::SleepingLock))
        expect { |b| class_instance.in_lock(unique_key, &b) }
          .to yield_with_args(false, an_instance_of(described_class::SleepingLock))
        expect { |b| class_instance.in_lock(unique_key, &b) }
          .to yield_with_args(false, an_instance_of(described_class::SleepingLock))
      end

      it 'cancels the exclusive lease after the block' do
        expect(lease).to receive(:cancel).once

        subject
      end
    end

    context 'when the lease is obtained already' do
      let!(:lease) { stub_exclusive_lease_taken(unique_key) }

      it 'retries to obtain a lease and raises an error' do
        expect(lease).to receive(:try_obtain).exactly(11).times

        expect { subject }.to raise_error('Failed to obtain a lock')
      end

      context 'when ttl is specified' do
        let(:options) { { ttl: 10.minutes } }

        it 'receives the specified argument' do
          expect(Gitlab::ExclusiveLease).to receive(:new).with(unique_key, { timeout: 10.minutes })

          expect { subject }.to raise_error('Failed to obtain a lock')
        end
      end

      context 'when retry count is specified' do
        let(:options) { { retries: 3 } }

        it 'retries for the specified times' do
          expect(lease).to receive(:try_obtain).exactly(4).times

          expect { subject }.to raise_error('Failed to obtain a lock')
        end

        context 'when lease is granted after retry' do
          it 'yields block with true' do
            expect(lease).to receive(:try_obtain).exactly(3).times { nil }
            expect(lease).to receive(:try_obtain).once { unique_key }

            expect { |b| class_instance.in_lock(unique_key, &b) }
              .to yield_with_args(true, an_instance_of(described_class::SleepingLock))
          end
        end
      end

      context 'when we specify no retries' do
        let(:options) { { retries: 0 } }

        it 'never sleeps' do
          expect_any_instance_of(Gitlab::ExclusiveLeaseHelpers::SleepingLock).not_to receive(:sleep)

          expect { subject }.to raise_error('Failed to obtain a lock')
        end
      end

      context 'when sleep second is specified' do
        let(:options) { { retries: 1, sleep_sec: 0.05.seconds } }

        it 'receives the specified argument' do
          expect_any_instance_of(Gitlab::ExclusiveLeaseHelpers::SleepingLock).to receive(:sleep).with(0.05.seconds).once

          expect { subject }.to raise_error('Failed to obtain a lock')
        end
      end

      context 'when sleep second is specified as a lambda' do
        let(:options) { { retries: 2, sleep_sec: ->(num) { 0.1 + num } } }

        it 'receives the specified argument' do
          expect_any_instance_of(Gitlab::ExclusiveLeaseHelpers::SleepingLock).to receive(:sleep).with(1.1.seconds).once
          expect_any_instance_of(Gitlab::ExclusiveLeaseHelpers::SleepingLock).to receive(:sleep).with(2.1.seconds).once

          expect { subject }.to raise_error('Failed to obtain a lock')
        end
      end
    end

    describe 'instrumentation', :request_store do
      let!(:lease) { stub_exclusive_lease_taken(unique_key) }

      subject do
        class_instance.in_lock(unique_key, sleep_sec: 0.1, retries: 3) do
          sleep 0.1
        end
      end

      it 'increments lock requested count and computes the duration waiting for the lock and holding the lock' do
        expect(lease).to receive(:try_obtain).exactly(3).times.and_return(nil)
        expect(lease).to receive(:try_obtain).once.and_return(unique_key)

        subject

        expect(Gitlab::Instrumentation::ExclusiveLock.requested_count).to eq(1)
        expect(Gitlab::Instrumentation::ExclusiveLock.wait_duration).to be_between(0.3, 0.31)
        expect(Gitlab::Instrumentation::ExclusiveLock.hold_duration).to be_between(0.1, 0.11)
      end

      context 'when exclusive lease is not obtained' do
        it 'increments lock requested count and computes the duration waiting for the lock' do
          expect(lease).to receive(:try_obtain).exactly(4).times.and_return(nil)

          expect { subject }.to raise_error('Failed to obtain a lock')

          expect(Gitlab::Instrumentation::ExclusiveLock.requested_count).to eq(1)
          expect(Gitlab::Instrumentation::ExclusiveLock.wait_duration).to be_between(0.3, 0.31)
          expect(Gitlab::Instrumentation::ExclusiveLock.hold_duration).to eq(0)
        end
      end
    end
  end
end
