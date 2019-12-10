# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::ExpiringWorker, type: :worker do
  subject(:worker) { described_class.new }

  describe '#perform' do
    context 'when a token needs to be notified' do
      let!(:pat) { create(:personal_access_token, expires_at: 5.days.from_now) }

      it 'uses notification service to send the email' do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).to receive(:access_token_about_to_expire).with(pat.user)
        end

        worker.perform
      end

      it 'marks the notification as delivered' do
        expect { worker.perform }.to change { pat.reload.expire_notification_delivered }.from(false).to(true)
      end
    end

    context 'when no tokens need to be notified' do
      let!(:pat) { create(:personal_access_token, expires_at: 5.days.from_now, expire_notification_delivered: true) }

      it "doesn't use notification service to send the email" do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).not_to receive(:access_token_about_to_expire).with(pat.user)
        end

        worker.perform
      end

      it "doesn't change the notificationd delivered of the token" do
        expect { worker.perform }.not_to change { pat.reload.expire_notification_delivered }
      end
    end
  end
end
