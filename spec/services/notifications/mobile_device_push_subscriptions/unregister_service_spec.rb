# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notifications::MobileDevicePushSubscriptions::UnregisterService, feature_category: :notifications do
  let_it_be(:user) { create(:user) }

  let(:device_token) { SecureRandom.hex(32) }

  def unregister(user:, device_token:)
    described_class.new(user: user, device_token: device_token).execute
  end

  describe '#execute' do
    it 'deletes the user subscriptions for the token across environments' do
      create(:mobile_device_push_subscription, user: user, device_token: device_token)
      create(:mobile_device_push_subscription, :sandbox, user: user, device_token: device_token)
      other = create(:mobile_device_push_subscription, user: user)

      response = unregister(user: user, device_token: device_token)

      expect(response).to be_success
      expect(user.mobile_device_push_subscriptions).to contain_exactly(other)
    end

    it 'does not delete another user\'s subscription for the same token' do
      other_user = create(:user)
      subscription = create(:mobile_device_push_subscription, user: other_user, device_token: device_token)

      response = unregister(user: user, device_token: device_token)

      expect(response).to be_error
      expect(subscription.reload).to be_persisted
    end

    it 'returns a not_found error for an unknown token' do
      response = unregister(user: user, device_token: device_token)

      expect(response).to be_error
      expect(response.reason).to eq(:not_found)
    end
  end
end
