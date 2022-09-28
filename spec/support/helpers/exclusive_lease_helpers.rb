# frozen_string_literal: true

module ExclusiveLeaseHelpers
  def stub_exclusive_lease(key = nil, uuid = 'uuid', renew: false, timeout: nil)
    prepare_exclusive_lease_stub

    key     ||= instance_of(String)
    timeout ||= instance_of(Integer)

    lease = instance_double(
      Gitlab::ExclusiveLease,
      try_obtain: uuid,
      exists?: true,
      renew: renew,
      cancel: nil,
      ttl: timeout
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

  private

  # This prepares the stub to be able to stub specific lease keys
  # while allowing unstubbed lease keys to behave as original.
  #
  # allow(Gitlab::ExclusiveLease).to receive(:new).and_call_original
  # can only be called once to prevent resetting stubs when
  # `stub_exclusive_lease` is called multiple times.
  def prepare_exclusive_lease_stub
    return if @exclusive_lease_allowed_to_call_original

    allow(Gitlab::ExclusiveLease)
      .to receive(:new).and_call_original

    @exclusive_lease_allowed_to_call_original = true
  end
end
