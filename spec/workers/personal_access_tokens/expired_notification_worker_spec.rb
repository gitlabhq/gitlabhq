# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::ExpiredNotificationWorker, type: :worker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when a token has expired' do
      let(:expired_today) { create(:personal_access_token, expires_at: Date.current) }

      context 'when feature is enabled' do
        it 'uses notification service to send email to the user' do
          expect_next_instance_of(NotificationService) do |notification_service|
            expect(notification_service).to receive(:access_token_expired).with(expired_today.user)
          end

          worker.perform
        end

        it 'updates notified column' do
          expect { worker.perform }.to change { expired_today.reload.after_expiry_notification_delivered }.from(false).to(true)
        end
      end

      context 'when feature is disabled' do
        before do
          stub_feature_flags(expired_pat_email_notification: false)
        end

        it 'does not update notified column' do
          expect { worker.perform }.not_to change { expired_today.reload.after_expiry_notification_delivered }
        end

        it 'does not trigger email' do
          expect { worker.perform }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    shared_examples 'expiry notification is not required to be sent for the token' do
      it do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).not_to receive(:access_token_expired).with(token.user)
        end

        worker.perform
      end
    end

    context 'when token has expired in the past' do
      let(:token) { create(:personal_access_token, expires_at: Date.yesterday) }

      it_behaves_like 'expiry notification is not required to be sent for the token'
    end

    context 'when token is impersonated' do
      let(:token) { create(:personal_access_token, expires_at: Date.current, impersonation: true) }

      it_behaves_like 'expiry notification is not required to be sent for the token'
    end

    context 'when token is revoked' do
      let(:token) { create(:personal_access_token, expires_at: Date.current, revoked: true) }

      it_behaves_like 'expiry notification is not required to be sent for the token'
    end
  end
end
