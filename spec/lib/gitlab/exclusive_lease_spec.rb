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

  describe '#try_obtain_with_ttl' do
    it 'cannot obtain twice before the lease has expired' do
      lease = described_class.new(unique_key, timeout: 3600)

      ttl_lease = lease.try_obtain_with_ttl

      expect(ttl_lease[:uuid]).to be_present
      expect(ttl_lease[:ttl]).to eq(0)

      second_ttl_lease = lease.try_obtain_with_ttl

      expect(second_ttl_lease[:uuid]).to be false
      expect(second_ttl_lease[:ttl]).to be > 0
    end

    it 'can obtain after the lease has expired' do
      timeout = 1
      lease = described_class.new(unique_key, timeout: 1)

      sleep(2 * timeout) # lease should have expired now

      ttl_lease = lease.try_obtain_with_ttl

      expect(ttl_lease[:uuid]).to be_present
      expect(ttl_lease[:ttl]).to eq(0)
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

  describe '#same_uuid?' do
    it 'returns true for an existing lease' do
      lease = described_class.new(unique_key, timeout: 3600)
      lease.try_obtain

      expect(lease.same_uuid?).to eq(true)
    end

    it 'returns false for a lease that does not exist' do
      described_class.new(unique_key, timeout: 3600).try_obtain

      lease = described_class.new(unique_key, timeout: 3600)

      expect(lease.same_uuid?).to eq(false)
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

  describe '.cancel' do
    it 'can cancel a lease' do
      uuid = new_lease(unique_key)
      expect(uuid).to be_present
      expect(new_lease(unique_key)).to eq(false)

      described_class.cancel(unique_key, uuid)
      expect(new_lease(unique_key)).to be_present
    end

    def new_lease(key)
      described_class.new(key, timeout: 3600).try_obtain
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
