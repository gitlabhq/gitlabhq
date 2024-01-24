# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryUpdateRemoteMirrorWorker, :clean_gitlab_redis_shared_state, feature_category: :source_code_management do
  let_it_be(:remote_mirror) { create(:remote_mirror) }

  let(:scheduled_time) { Time.current - 5.minutes }

  around do |example|
    freeze_time { example.run }
  end

  def expect_mirror_service_to_return(mirror, result, tries = 0)
    expect_next_instance_of(Projects::UpdateRemoteMirrorService) do |service|
      expect(service).to receive(:execute).with(mirror, tries).and_return(result)
    end
  end

  describe '#perform' do
    subject { described_class.new }

    it 'calls out to the service to perform the update' do
      expect_mirror_service_to_return(remote_mirror, status: :success)

      subject.perform(remote_mirror.id, scheduled_time)
    end

    it 'does not do anything if the mirror was already updated' do
      remote_mirror.update!(last_update_started_at: Time.current, update_status: :finished)

      expect(Projects::UpdateRemoteMirrorService).not_to receive(:new)

      subject.perform(remote_mirror.id, scheduled_time)
    end

    it 'schedules a retry when the mirror is marked for retrying' do
      remote_mirror = create(:remote_mirror, update_status: :to_retry)
      expect_mirror_service_to_return(remote_mirror, status: :error, message: 'Retry!')

      expect(described_class)
        .to receive(:perform_in)
              .with(remote_mirror.backoff_delay, remote_mirror.id, scheduled_time, 1)

      subject.perform(remote_mirror.id, scheduled_time)
    end

    it 'clears the lease if there was an unexpected exception' do
      expect_next_instance_of(Projects::UpdateRemoteMirrorService) do |service|
        expect(service).to receive(:execute).with(remote_mirror, 1).and_raise('Unexpected!')
      end
      expect { subject.perform(remote_mirror.id, Time.current, 1) }.to raise_error('Unexpected!')

      lease = Gitlab::ExclusiveLease.new("#{described_class.name}:#{remote_mirror.id}", timeout: 1.second)

      expect(lease.try_obtain).not_to be_nil
    end

    it 'retries 3 times for the worker to finish before rescheduling' do
      expect(subject).to receive(:in_lock).with(
        "#{described_class.name}:#{remote_mirror.id}",
        retries: 3,
        ttl: remote_mirror.max_runtime,
        sleep_sec: described_class::LOCK_WAIT_TIME
      ).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)

      expect(described_class)
        .to receive(:perform_in)
        .with(remote_mirror.backoff_delay, remote_mirror.id, scheduled_time, 0)

      subject.perform(remote_mirror.id, scheduled_time)
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [remote_mirror.id, scheduled_time] }
  end
end
