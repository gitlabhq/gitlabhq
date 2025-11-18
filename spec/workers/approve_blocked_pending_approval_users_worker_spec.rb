# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApproveBlockedPendingApprovalUsersWorker, type: :worker, feature_category: :user_profile do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:active_user) { create(:user) }
  let_it_be(:blocked_user) { create(:user, state: 'blocked_pending_approval') }

  describe '#perform' do
    subject do
      described_class.new.perform(admin.id)
    end

    context 'when user is not found' do
      let(:non_existing_user_id) { non_existing_record_id }

      it 'logs a warning and does not execute any side effects', :aggregate_failures do
        expect(Sidekiq.logger).to receive(:warn).with(
          class: described_class.name,
          user_id: non_existing_user_id,
          message: 'user not found'
        )

        expect(Users::ApproveService).not_to receive(:new)
        expect(User).not_to receive(:blocked_pending_approval)

        described_class.new.perform(non_existing_user_id)
      end
    end

    it 'calls ApproveService for users in blocked_pending_approval state' do
      expect_next_instance_of(Users::ApproveService, admin) do |service|
        expect(service).to receive(:execute).with(blocked_user)
      end

      subject
    end

    it 'does not call ApproveService for active users' do
      expect_next_instance_of(Users::ApproveService, admin) do |service|
        expect(service).not_to receive(:execute).with(active_user)
      end

      subject
    end
  end
end
