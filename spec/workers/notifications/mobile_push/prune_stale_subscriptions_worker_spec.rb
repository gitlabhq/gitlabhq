# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notifications::MobilePush::PruneStaleSubscriptionsWorker, feature_category: :notifications do
  let_it_be(:user) { create(:user) }

  subject(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    it 'deletes subscriptions not seen since the cutoff and keeps the rest' do
      create(:mobile_device_push_subscription, user: user, last_seen_at: 91.days.ago)
      create(:mobile_device_push_subscription, user: user, last_seen_at: 92.days.ago)
      fresh = create(:mobile_device_push_subscription, user: user, last_seen_at: 89.days.ago)
      fresh_default = create(:mobile_device_push_subscription, user: user)

      expect { worker.perform }.to change { Notifications::MobileDevicePushSubscription.count }.by(-2)
      expect(Notifications::MobileDevicePushSubscription.all).to contain_exactly(fresh, fresh_default)
    end

    it 'logs the number of deleted subscriptions' do
      create(:mobile_device_push_subscription, user: user, last_seen_at: 91.days.ago)

      expect(worker).to receive(:log_extra_metadata_on_done).with(:deleted_count, 1)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:cutoff, kind_of(String))

      worker.perform
    end

    it 'does nothing when no subscription is stale' do
      create(:mobile_device_push_subscription, user: user, last_seen_at: 1.day.ago)

      expect { worker.perform }.not_to change { Notifications::MobileDevicePushSubscription.count }
    end
  end
end
