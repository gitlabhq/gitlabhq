# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::ExpiredNotificationWorker, type: :worker, feature_category: :system_access do
  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when a token has expired' do
      let(:expired_today) { create(:personal_access_token, expires_at: Date.current) }

      it 'uses notification service to send email to the user' do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).to receive(:access_token_expired).with(expired_today.user, [expired_today.name])
        end

        worker.perform
      end

      it 'updates notified column' do
        expect { worker.perform }.to change { expired_today.reload.after_expiry_notification_delivered }.from(false).to(true)
      end
    end

    shared_examples 'expiry notification is not required to be sent for the token' do
      it do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).not_to receive(:access_token_expired).with(token.user, [token.name])
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
