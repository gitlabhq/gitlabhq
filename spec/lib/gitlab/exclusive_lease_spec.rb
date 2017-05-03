require 'spec_helper'

describe Gitlab::ExclusiveLease, type: :redis do
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
end
