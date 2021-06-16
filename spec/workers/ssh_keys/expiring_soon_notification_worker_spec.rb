# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SshKeys::ExpiringSoonNotificationWorker, type: :worker do
  subject(:worker) { described_class.new }

  it 'uses a cronjob queue' do
    expect(worker.sidekiq_options_hash).to include(
      'queue' => 'cronjob:ssh_keys_expiring_soon_notification',
      'queue_namespace' => :cronjob
    )
  end

  describe '#perform' do
    let_it_be(:user) { create(:user) }

    context 'with key expiring soon' do
      let_it_be_with_reload(:expiring_soon) { create(:key, expires_at: 6.days.from_now, user: user) }

      it 'invoke the notification service' do
        expect_next_instance_of(Keys::ExpiryNotificationService) do |expiry_service|
          expect(expiry_service).to receive(:execute)
        end

        worker.perform
      end

      it 'updates notified column' do
        expect { worker.perform }.to change { expiring_soon.reload.before_expiry_notification_delivered_at }
      end

      include_examples 'an idempotent worker' do
        subject do
          perform_multiple(worker: worker)
        end
      end
    end

    context 'when key has expired in the past' do
      let_it_be(:expired_past) { create(:key, expires_at: 1.day.ago, user: user) }

      it 'does not update notified column' do
        expect { worker.perform }.not_to change { expired_past.reload.before_expiry_notification_delivered_at }
      end
    end

    context 'when key is not expiring soon' do
      let_it_be(:expires_future) { create(:key, expires_at: 8.days.from_now, user: user) }

      it 'does not update notified column' do
        expect { worker.perform }.not_to change { expires_future.reload.before_expiry_notification_delivered_at }
      end
    end
  end
end
