# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExclusiveLease, :request_store,
  :clean_gitlab_redis_shared_state, feature_category: :shared do
  let(:unique_key) { SecureRandom.hex(10) }

  describe '#try_obtain' do
    it 'cannot obtain twice before the lease has expired' do
      lease = described_class.new(unique_key, timeout: 3600)
      expect(lease.try_obtain).to be_present
      expect(lease.try_obtain).to eq(false)
    end

    it 'can obtain after the lease has expired' do
      timeout = 1
      lease = described_class.new(unique_key, timeout: timeout)
      lease.try_obtain # start the lease
      sleep(2 * timeout) # lease should have expired now
      expect(lease.try_obtain).to be_present
    end

    context 'when lease attempt within pg transaction' do
      let(:lease) { described_class.new(unique_key, timeout: 1) }

      subject(:lease_attempt) { lease.try_obtain }

      context 'in development/test environment' do
        it 'raises error within ci db', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446120' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

          Ci::Pipeline.transaction do
            expect { lease_attempt }.to raise_error(Gitlab::ExclusiveLease::LeaseWithinTransactionError)
          end
        end

        it 'raises error within main db', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446121' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

          ApplicationRecord.transaction do
            expect { lease_attempt }.to raise_error(Gitlab::ExclusiveLease::LeaseWithinTransactionError)
          end
        end
      end

      context 'in production environment' do
        before do
          stub_rails_env('production')
        end

        it 'logs error within ci db', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446122' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

          Ci::Pipeline.transaction { lease_attempt }
        end

        it 'logs error within main db', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446123' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

          ApplicationRecord.transaction { lease_attempt }
        end
      end
    end

    context 'when allowed to attempt within pg transaction' do
      shared_examples 'no error tracking performed' do
        it 'does not raise error within ci db' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception).and_call_original

          Ci::Pipeline.transaction { allowed_lease_attempt }
        end

        it 'does not raise error within main db' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception).and_call_original

          ApplicationRecord.transaction { allowed_lease_attempt }
        end
      end

      let(:lease) { described_class.new(unique_key, timeout: 1) }

      subject(:allowed_lease_attempt) { described_class.skipping_transaction_check { lease.try_obtain } }

      it_behaves_like 'no error tracking performed'

      context 'in production environment' do
        before do
          stub_rails_env('production')
        end

        it_behaves_like 'no error tracking performed'
      end
    end
  end

  describe '.redis_shared_state_key' do
    it 'provides a namespaced key' do
      expect(described_class.redis_shared_state_key(unique_key))
        .to start_with(described_class::PREFIX)
        .and include(unique_key)
    end
  end

  describe '.ensure_prefixed_key' do
    it 'does not double prefix a key' do
      prefixed = described_class.redis_shared_state_key(unique_key)

      expect(described_class.ensure_prefixed_key(unique_key))
        .to eq(described_class.ensure_prefixed_key(prefixed))
    end

    it 'raises errors when there is no key' do
      expect { described_class.ensure_prefixed_key(nil) }.to raise_error(described_class::NoKey)
    end
  end

  describe '#renew' do
    it 'returns true when we have the existing lease' do
      lease = described_class.new(unique_key, timeout: 3600)
      expect(lease.try_obtain).to be_present
      expect(lease.renew).to be_truthy
    end

    it 'returns false when we dont have a lease' do
      lease = described_class.new(unique_key, timeout: 3600)
      expect(lease.renew).to be_falsey
    end
  end

  describe 'cancellation' do
    def new_lease(key)
      described_class.new(key, timeout: 3600)
    end

    shared_examples 'cancelling a lease' do
      let(:lease) { new_lease(unique_key) }

      it 'releases the held lease' do
        uuid = lease.try_obtain
        expect(uuid).to be_present
        expect(new_lease(unique_key).try_obtain).to eq(false)

        cancel_lease(uuid)

        expect(new_lease(unique_key).try_obtain).to be_present
      end
    end

    describe '.cancel' do
      def cancel_lease(uuid)
        described_class.cancel(release_key, uuid)
      end

      context 'when called with the unprefixed key' do
        it_behaves_like 'cancelling a lease' do
          let(:release_key) { unique_key }
        end
      end

      context 'when called with the prefixed key' do
        it_behaves_like 'cancelling a lease' do
          let(:release_key) { described_class.redis_shared_state_key(unique_key) }
        end
      end

      it 'does not raise errors when given a nil key' do
        expect { described_class.cancel(nil, nil) }.not_to raise_error
      end
    end

    describe '#cancel' do
      def cancel_lease(_uuid)
        lease.cancel
      end

      it_behaves_like 'cancelling a lease'

      it 'is safe to call even if the lease was never obtained' do
        lease = new_lease(unique_key)

        lease.cancel

        expect(new_lease(unique_key).try_obtain).to be_present
      end
    end
  end

  describe '.reset_all!' do
    it 'removes all existing lease keys from redis' do
      uuid = described_class.new(unique_key, timeout: 3600).try_obtain

      expect(described_class.get_uuid(unique_key)).to eq(uuid)

      described_class.reset_all!

      expect(described_class.get_uuid(unique_key)).to be_falsey
    end
  end

  describe '#exists?' do
    it 'returns true for an existing lease' do
      lease = described_class.new(unique_key, timeout: 3600)
      lease.try_obtain

      expect(lease.exists?).to eq(true)
    end

    it 'returns false for a lease that does not exist' do
      lease = described_class.new(unique_key, timeout: 3600)

      expect(lease.exists?).to eq(false)
    end
  end

  describe '.get_uuid' do
    it 'gets the uuid if lease with the key associated exists' do
      uuid = described_class.new(unique_key, timeout: 3600).try_obtain

      expect(described_class.get_uuid(unique_key)).to eq(uuid)
    end

    it 'returns false if the lease does not exist' do
      expect(described_class.get_uuid(unique_key)).to be false
    end
  end

  describe '#ttl' do
    it 'returns the TTL of the Redis key' do
      lease = described_class.new('kittens', timeout: 100)
      lease.try_obtain

      expect(lease.ttl <= 100).to eq(true)
    end

    it 'returns nil when the lease does not exist' do
      lease = described_class.new('kittens', timeout: 10)

      expect(lease.ttl).to be_nil
    end
  end

  describe '.throttle' do
    it 'prevents repeated execution of the block' do
      number = 0

      action = -> { described_class.throttle(1) { number += 1 } }

      action.call
      action.call

      expect(number).to eq 1
    end

    it 'is distinct by block' do
      number = 0

      described_class.throttle(1) { number += 1 }
      described_class.throttle(1) { number += 1 }

      expect(number).to eq 2
    end

    it 'is distinct by key' do
      number = 0

      action = ->(k) { described_class.throttle(k) { number += 1 } }

      action.call(:a)
      action.call(:b)
      action.call(:a)

      expect(number).to eq 2
    end

    it 'allows a group to be passed' do
      number = 0

      described_class.throttle(1, group: :a) { number += 1 }
      described_class.throttle(1, group: :b) { number += 1 }
      described_class.throttle(1, group: :a) { number += 1 }
      described_class.throttle(1, group: :b) { number += 1 }

      expect(number).to eq 2
    end

    it 'defaults to a 60min timeout' do
      expect(described_class).to receive(:new).with(anything, hash_including(timeout: 1.hour.to_i)).and_call_original

      described_class.throttle(1) {}
    end

    it 'allows count to be specified' do
      expect(described_class)
        .to receive(:new)
              .with(anything, hash_including(timeout: 15.minutes.to_i))
              .and_call_original

      described_class.throttle(1, count: 4) {}
    end

    it 'allows period to be specified' do
      expect(described_class)
        .to receive(:new)
              .with(anything, hash_including(timeout: 1.day.to_i))
              .and_call_original

      described_class.throttle(1, period: 1.day) {}
    end

    it 'allows period and count to be specified' do
      expect(described_class)
        .to receive(:new)
              .with(anything, hash_including(timeout: 30.minutes.to_i))
              .and_call_original

      described_class.throttle(1, count: 48, period: 1.day) {}
    end
  end
end
