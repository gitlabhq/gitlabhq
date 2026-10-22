# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::TransferMergeRequestDiffCommitUsersWorker,
  :aggregate_failures, feature_category: :code_review_workflow do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be(:group) { create(:group, organization: old_organization) }

  subject(:perform) { described_class.new.perform(group.id, old_organization.id, new_organization.id) }

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [group.id, old_organization.id, new_organization.id] }
  end

  describe '#perform' do
    it 'calls MergeRequestDiffCommitUsersService#execute with the correct arguments' do
      expect_next_instance_of(
        Organizations::DataSeverance::MergeRequestDiffCommitUsersService,
        group: group,
        old_organization: old_organization,
        new_organization: new_organization
      ) do |service|
        expect(service).to receive(:execute).with(cursor: nil)
      end

      perform
    end

    it 'passes an explicit cursor to execute when provided' do
      expect_next_instance_of(
        Organizations::DataSeverance::MergeRequestDiffCommitUsersService,
        group: group,
        old_organization: old_organization,
        new_organization: new_organization
      ) do |service|
        expect(service).to receive(:execute).with(cursor: 42)
      end

      described_class.new.perform(group.id, old_organization.id, new_organization.id, 42)
    end

    it 're-enqueues with the last project cursor when the runtime limit is exceeded' do
      allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |limiter|
        allow(limiter).to receive(:over_time?).and_return(true)
      end

      allow_next_instance_of(
        Organizations::DataSeverance::MergeRequestDiffCommitUsersService,
        group: group,
        old_organization: old_organization,
        new_organization: new_organization
      ) do |service|
        allow(service).to receive(:execute).with(cursor: nil).and_yield(99)
      end

      expect(described_class)
        .to receive(:perform_in)
        .with(described_class::REQUEUE_DELAY, group.id, old_organization.id, new_organization.id, 99)

      perform
    end

    it 'does not re-enqueue when the runtime limit is not exceeded' do
      allow_next_instance_of(Gitlab::Metrics::RuntimeLimiter) do |limiter|
        allow(limiter).to receive(:over_time?).and_return(false)
      end

      allow_next_instance_of(
        Organizations::DataSeverance::MergeRequestDiffCommitUsersService,
        group: group,
        old_organization: old_organization,
        new_organization: new_organization
      ) do |service|
        allow(service).to receive(:execute).with(cursor: nil).and_yield(99)
      end

      expect(described_class).not_to receive(:perform_in)

      perform
    end

    context 'when the group does not exist' do
      it 'does not call the service and logs a message' do
        expect(Organizations::DataSeverance::MergeRequestDiffCommitUsersService).not_to receive(:new)

        expect(described_class.new.perform(-1, old_organization.id, new_organization.id)).to be_nil
      end
    end

    context 'when the old organization does not exist' do
      it 'does not call the service and logs a message' do
        expect(Organizations::DataSeverance::MergeRequestDiffCommitUsersService).not_to receive(:new)

        expect(described_class.new.perform(group.id, -1, new_organization.id)).to be_nil
      end
    end

    context 'when the new organization does not exist' do
      it 'does not call the service and logs a message' do
        expect(Organizations::DataSeverance::MergeRequestDiffCommitUsersService).not_to receive(:new)

        expect(described_class.new.perform(group.id, old_organization.id, -1)).to be_nil
      end
    end
  end
end
