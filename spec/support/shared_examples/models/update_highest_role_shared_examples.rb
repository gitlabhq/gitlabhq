# frozen_string_literal: true

# requires a subject and a user_id
RSpec.shared_examples 'update highest role with exclusive lease' do
  include ExclusiveLeaseHelpers

  let(:lease_key) { "update_highest_role:#{user_id}" }

  before do
    allow(Gitlab::ExclusiveLease).to receive(:new).and_call_original
  end

  context 'when lease is obtained', :clean_gitlab_redis_shared_state do
    it 'takes the lease but does not release it', :aggregate_failures do
      expect_to_obtain_exclusive_lease(lease_key, 'uuid', timeout: described_class::HIGHEST_ROLE_LEASE_TIMEOUT)
      expect(Gitlab::ExclusiveLease).not_to receive(:cancel).with(lease_key, 'uuid')

      subject
    end

    it 'schedules a job in the future', :aggregate_failures do
      allow_next_instance_of(Gitlab::ExclusiveLease) do |instance|
        allow(instance).to receive(:try_obtain).and_return('uuid')
      end

      expect(UpdateHighestRoleWorker).to receive(:perform_in).with(described_class::HIGHEST_ROLE_JOB_DELAY, user_id).and_call_original

      expect { subject }.to change { UpdateHighestRoleWorker.jobs.size }.by(1)
    end
  end

  context 'when lease cannot be obtained', :clean_gitlab_redis_shared_state do
    it 'only schedules one job' do
      stub_exclusive_lease_taken(lease_key, timeout: described_class::HIGHEST_ROLE_LEASE_TIMEOUT)

      expect { subject }.not_to change { UpdateHighestRoleWorker.jobs.size }
    end
  end
end

# requires a subject and a user_id
RSpec.shared_examples 'does not update the highest role' do
  it 'does not obtain an exclusive lease' do
    allow(Gitlab::ExclusiveLease).to receive(:new).and_call_original

    lease = stub_exclusive_lease("update_highest_role:#{user_id}", 'uuid', timeout: described_class::HIGHEST_ROLE_LEASE_TIMEOUT)

    expect(lease).not_to receive(:try_obtain)

    subject
  end
end
