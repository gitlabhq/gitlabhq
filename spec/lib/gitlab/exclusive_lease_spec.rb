require 'spec_helper'

describe Gitlab::ExclusiveLease, type: :redis do
  let(:unique_key) { SecureRandom.hex(10) }

  describe '#try_obtain' do
    it 'cannot obtain twice before the lease has expired' do
      lease = Gitlab::ExclusiveLease.new(unique_key, timeout: 3600)
      expect(lease.try_obtain).to eq(true)
      expect(lease.try_obtain).to eq(false)
    end

    it 'can obtain after the lease has expired' do
      timeout = 1
      lease = Gitlab::ExclusiveLease.new(unique_key, timeout: timeout)
      lease.try_obtain # start the lease
      sleep(2 * timeout) # lease should have expired now
      expect(lease.try_obtain).to eq(true)
    end
  end

  describe '#exists?' do
    it 'returns true for an existing lease' do
      lease = Gitlab::ExclusiveLease.new(unique_key, timeout: 3600)
      lease.try_obtain

      expect(lease.exists?).to eq(true)
    end

    it 'returns false for a lease that does not exist' do
      lease = Gitlab::ExclusiveLease.new(unique_key, timeout: 3600)

      expect(lease.exists?).to eq(false)
    end
  end
end
