# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabServicePingWorker, :clean_gitlab_redis_shared_state do
  before do
    allow_next_instance_of(ServicePing::SubmitService) { |service| allow(service).to receive(:execute) }
    allow(subject).to receive(:sleep)
  end

  it 'does not run for GitLab.com' do
    allow(Gitlab).to receive(:com?).and_return(true)
    expect(ServicePing::SubmitService).not_to receive(:new)

    subject.perform
  end

  it 'delegates to ServicePing::SubmitService' do
    expect_next_instance_of(ServicePing::SubmitService) { |service| expect(service).to receive(:execute) }

    subject.perform
  end

  it "obtains a #{described_class::LEASE_TIMEOUT} second exclusive lease" do
    expect(Gitlab::ExclusiveLeaseHelpers::SleepingLock)
      .to receive(:new)
      .with(described_class::LEASE_KEY, hash_including(timeout: described_class::LEASE_TIMEOUT))
      .and_call_original

    subject.perform
  end

  it 'sleeps for between 0 and 60 seconds' do
    expect(subject).to receive(:sleep).with(0..60)

    subject.perform
  end

  context 'when lease is not obtained' do
    before do
      Gitlab::ExclusiveLease.new(described_class::LEASE_KEY, timeout: described_class::LEASE_TIMEOUT).try_obtain
    end

    it 'does not invoke ServicePing::SubmitService' do
      allow_next_instance_of(ServicePing::SubmitService) { |service| expect(service).not_to receive(:execute) }

      expect { subject.perform }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
    end
  end
end
