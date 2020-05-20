# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ExclusiveLease, :clean_gitlab_redis_shared_state do
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

  describe '.reset_all!' do
    it 'removes all existing lease keys from redis' do
      uuid = described_class.new(unique_key, timeout: 3600).try_obtain

      expect(described_class.get_uuid(unique_key)).to eq(uuid)

      described_class.reset_all!

      expect(described_class.get_uuid(unique_key)).to be_falsey
    end
  end
end
