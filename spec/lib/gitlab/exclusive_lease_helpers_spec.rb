# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ExclusiveLeaseHelpers, :clean_gitlab_redis_shared_state do
  include ::ExclusiveLeaseHelpers

  let(:class_instance) { (Class.new { include ::Gitlab::ExclusiveLeaseHelpers }).new }
  let(:unique_key) { SecureRandom.hex(10) }

  describe '#in_lock' do
    subject { class_instance.in_lock(unique_key, **options) { } }

    let(:options) { {} }

    context 'when unique key is not set' do
      let(:unique_key) { }

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'when the lease is not obtained yet' do
      before do
        stub_exclusive_lease(unique_key, 'uuid')
      end

      it 'calls the given block' do
        expect { |b| class_instance.in_lock(unique_key, &b) }.to yield_with_args(false)
      end

      it 'calls the given block continuously' do
        expect { |b| class_instance.in_lock(unique_key, &b) }.to yield_with_args(false)
        expect { |b| class_instance.in_lock(unique_key, &b) }.to yield_with_args(false)
        expect { |b| class_instance.in_lock(unique_key, &b) }.to yield_with_args(false)
      end

      it 'cancels the exclusive lease after the block' do
        expect_to_cancel_exclusive_lease(unique_key, 'uuid')

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
          expect(Gitlab::ExclusiveLease).to receive(:new).with(unique_key, { timeout: 10.minutes } )

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

            expect { |b| class_instance.in_lock(unique_key, &b) }.to yield_with_args(true)
          end
        end
      end

      context 'when sleep second is specified' do
        let(:options) { { retries: 0, sleep_sec: 0.05.seconds } }

        it 'receives the specified argument' do
          expect(class_instance).to receive(:sleep).with(0.05.seconds).once

          expect { subject }.to raise_error('Failed to obtain a lock')
        end
      end
    end
  end
end
