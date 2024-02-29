# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RejectService, feature_category: :user_management do
  let_it_be(:current_user) { create(:admin) }

  let(:user) { create(:user, :blocked_pending_approval) }

  subject(:execute) { described_class.new(current_user).execute(user) }

  describe '#execute' do
    context 'failures' do
      context 'when the executor user is not allowed to reject users' do
        let(:current_user) { create(:user) }

        it 'returns error result' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to match(/You are not allowed to reject a user/)
        end
      end

      context 'when the executor user is an admin in admin mode', :enable_admin_mode do
        context 'when user is not in pending approval state' do
          let(:user) { create(:user, state: 'active') }

          it 'returns error result' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message])
              .to match(/User does not have a pending request/)
          end
        end
      end
    end

    context 'success' do
      context 'when the executor user is an admin in admin mode', :enable_admin_mode do
        it 'initiates user removal', :sidekiq_inline do
          subject

          expect(subject[:status]).to eq(:success)
          expect(
            Users::GhostUserMigration.where(user: user, initiator_user: current_user)
          ).to be_exists
        end

        it 'emails the user on rejection' do
          expect_next_instance_of(NotificationService) do |notification|
            allow(notification).to receive(:user_admin_rejection).with(user.name, user.notification_email_or_default)
          end

          subject
        end

        it 'logs rejection in application logs' do
          allow(Gitlab::AppLogger).to receive(:info)

          subject

          expect(Gitlab::AppLogger).to have_received(:info).with(
            message: "User instance access request rejected",
            username: user.username.to_s,
            user_id: user.id,
            email: user.email.to_s,
            rejected_by: current_user.username.to_s,
            ip_address: current_user.current_sign_in_ip.to_s
          )
        end
      end
    end

    context 'audit events' do
      context 'when not licensed' do
        before do
          stub_licensed_features(admin_audit_log: false)
        end

        it 'does not log any audit event' do
          expect { subject }.not_to change(AuditEvent, :count)
        end
      end
    end
  end
end
