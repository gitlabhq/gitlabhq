# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MobilePush::Recipient, feature_category: :notifications do
  let(:user) { create(:user) }

  subject(:recipient) { described_class.new(user) }

  describe '#skip_reason' do
    it 'is nil for an active user with the flag on and a phone' do
      create(:mobile_device_push_subscription, user: user)

      expect(recipient.skip_reason).to be_nil
    end

    it 'names a missing or inactive user' do
      expect(described_class.new(nil).skip_reason).to eq(:skipped_user_inactive)

      user.block!

      expect(recipient.skip_reason).to eq(:skipped_user_inactive)
    end

    it 'names the per-user push flag' do
      stub_feature_flags(mobile_push_notifications: false)

      expect(recipient.skip_reason).to eq(:skipped_setting_disabled)
    end

    it 'names missing phones' do
      expect(recipient.skip_reason).to eq(:skipped_no_subscription)
    end
  end

  describe '#subscriptions' do
    it 'loads the phones once' do
      create_list(:mobile_device_push_subscription, 2, user: user)

      expect(recipient.subscriptions.size).to eq(2)
      expect { recipient.subscriptions }.not_to exceed_query_limit(0)
    end
  end
end
