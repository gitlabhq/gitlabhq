# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::ExpiryNotificationService, feature_category: :source_code_management do
  let_it_be_with_reload(:user) { create(:user) }

  let(:params) { { keys: user.keys, expiring_soon: expiring_soon } }

  subject { described_class.new(user, params) }

  shared_examples 'sends a notification' do
    it do
      perform_enqueued_jobs do
        subject.execute
      end
      should_email(user)
    end
  end

  shared_examples 'uses notification service to send email to the user' do |notification_method|
    it do
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).to receive(notification_method).with(key.user, [key.fingerprint])
      end

      subject.execute
    end
  end

  shared_examples 'does not send notification' do
    it do
      perform_enqueued_jobs do
        subject.execute
      end
      should_not_email(user)
    end
  end

  shared_examples 'creates todo' do
    it do
      perform_enqueued_jobs do
        expect { subject.execute }.to change { user.todos.count }.by(1)
      end
    end
  end

  shared_examples 'does not create todo' do
    it do
      perform_enqueued_jobs do
        expect { subject.execute }.not_to change { user.todos.count }
      end
    end
  end

  shared_context 'block user' do
    before do
      user.block!
    end
  end

  context 'with key expiring today', :mailer do
    let_it_be_with_reload(:key) { create(:key, expires_at: 10.minutes.from_now, user: user) }

    let(:expiring_soon) { false }

    context 'when user has permission to receive notification' do
      it_behaves_like 'creates todo'
      it_behaves_like 'sends a notification'

      it_behaves_like 'uses notification service to send email to the user', :ssh_key_expired

      it 'updates notified column' do
        expect { subject.execute }.to change { key.reload.expiry_notification_delivered_at }
      end
    end

    context 'when user does NOT have permission to receive notification' do
      include_context 'block user'

      it_behaves_like 'does not create todo'
      it_behaves_like 'does not send notification'

      it 'does not update notified column' do
        expect { subject.execute }.not_to change { key.reload.expiry_notification_delivered_at }
      end
    end
  end

  context 'with key expiring soon', :mailer do
    let_it_be_with_reload(:key) { create(:key, expires_at: 3.days.from_now, user: user) }

    let(:expiring_soon) { true }

    context 'when user has permission to receive notification' do
      it_behaves_like 'creates todo'
      it_behaves_like 'sends a notification'

      it_behaves_like 'uses notification service to send email to the user', :ssh_key_expiring_soon

      it 'updates notified column' do
        expect { subject.execute }.to change { key.reload.before_expiry_notification_delivered_at }
      end
    end

    context 'when user does NOT have permission to receive notification' do
      include_context 'block user'

      it_behaves_like 'does not create todo'
      it_behaves_like 'does not send notification'

      it 'does not update notified column' do
        expect { subject.execute }.not_to change { key.reload.before_expiry_notification_delivered_at }
      end
    end
  end
end
