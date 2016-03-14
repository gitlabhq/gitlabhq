require 'spec_helper'

describe Gitlab::ExclusiveLease do
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

  def unique_key
    SecureRandom.hex(10)
  end
end
