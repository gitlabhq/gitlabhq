require 'spec_helper'

describe Gitlab::ExclusiveLease do
  it 'is exclusive' do
    lease = Gitlab::ExclusiveLease.new(unique_key, timeout: 3600)
    expect(lease.try_obtain).to eq(true)
    expect(lease.try_obtain).to eq(false)
  end

  it 'expires' do
    timeout = 1
    lease = Gitlab::ExclusiveLease.new(unique_key, timeout: timeout)
    lease.try_obtain
    sleep(2 * timeout)
    expect(lease.try_obtain).to eq(true)
  end

  def unique_key
    SecureRandom.hex(10)
  end
end
