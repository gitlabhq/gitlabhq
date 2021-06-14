# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SshKeys::ExpiredNotificationWorker, type: :worker do
  subject(:worker) { described_class.new }

  it 'uses a cronjob queue' do
    expect(worker.sidekiq_options_hash).to include(
      'queue' => 'cronjob:ssh_keys_expired_notification',
      'queue_namespace' => :cronjob
    )
  end

  describe '#perform' do
    let_it_be(:user) { create(:user) }

    context 'with a large batch' do
      before do
        stub_const("SshKeys::ExpiredNotificationWorker::BATCH_SIZE", 5)
      end

      let_it_be_with_reload(:keys) { create_list(:key, 20, expires_at: 3.days.ago, user: user) }

      it 'updates all keys regardless of batch size' do
        worker.perform

        expect(keys.pluck(:expiry_notification_delivered_at)).not_to include(nil)
      end
    end

    context 'with expiring key today' do
      let_it_be_with_reload(:expired_today) { create(:key, expires_at: Time.current, user: user) }

      it 'invoke the notification service' do
        expect_next_instance_of(Keys::ExpiryNotificationService) do |expiry_service|
          expect(expiry_service).to receive(:execute)
        end

        worker.perform
      end

      it 'updates notified column' do
        expect { worker.perform }.to change { expired_today.reload.expiry_notification_delivered_at }
      end

      include_examples 'an idempotent worker' do
        subject do
          perform_multiple(worker: worker)
        end
      end
    end

    context 'when key has expired in the past' do
      let_it_be(:expired_past) { create(:key, expires_at: 1.day.ago, user: user) }

      it 'does update notified column' do
        expect { worker.perform }.to change { expired_past.reload.expiry_notification_delivered_at }
      end

      context 'when key has already been notified of expiration' do
        before do
          expired_past.update!(expiry_notification_delivered_at: 1.day.ago)
        end

        it 'does not update notified column' do
          expect { worker.perform }.not_to change { expired_past.reload.expiry_notification_delivered_at }
        end
      end
    end
  end
end
