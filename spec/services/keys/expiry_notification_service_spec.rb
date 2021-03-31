# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::ExpiryNotificationService do
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:expired_key) { create(:key, expires_at: Time.current, user: user) }

  let(:params) { { keys: keys } }

  subject { described_class.new(user, params) }

  context 'with expired key', :mailer do
    let(:keys) { user.keys }

    it 'sends a notification' do
      perform_enqueued_jobs do
        subject.execute
      end
      should_email(user)
    end

    it 'uses notification service to send email to the user' do
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).to receive(:ssh_key_expired).with(expired_key.user, [expired_key.fingerprint])
      end

      subject.execute
    end

    it 'updates notified column' do
      expect { subject.execute }.to change { expired_key.reload.expiry_notification_delivered_at }
    end

    context 'when user does not have permission to receive notification' do
      before do
        user.block!
      end

      it 'does not send notification' do
        perform_enqueued_jobs do
          subject.execute
        end
        should_not_email(user)
      end

      it 'does not update notified column' do
        expect { subject.execute }.not_to change { expired_key.reload.expiry_notification_delivered_at }
      end
    end
  end
end
