module ExclusiveLeaseHelpers
  def stub_exclusive_lease(key = nil, uuid = 'uuid', renew: false, timeout: nil)
    key     ||= instance_of(String)
    timeout ||= instance_of(Integer)

    lease = instance_double(
      Gitlab::ExclusiveLease,
      try_obtain: uuid,
      exists?: true,
      renew: renew
    )

    allow(Gitlab::ExclusiveLease)
      .to receive(:new)
      .with(key, timeout: timeout)
      .and_return(lease)

    lease
  end

  def stub_exclusive_lease_taken(key = nil, timeout: nil)
    stub_exclusive_lease(key, nil, timeout: timeout)
  end

  def expect_to_obtain_exclusive_lease(key, uuid = 'uuid', timeout: nil)
    lease = stub_exclusive_lease(key, uuid, timeout: timeout)

    expect(lease).to receive(:try_obtain)
  end

  def expect_to_cancel_exclusive_lease(key, uuid)
    expect(Gitlab::ExclusiveLease)
      .to receive(:cancel)
      .with(key, uuid)
  end
end
