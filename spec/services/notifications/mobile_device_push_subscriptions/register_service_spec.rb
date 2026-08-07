# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notifications::MobileDevicePushSubscriptions::RegisterService, feature_category: :notifications do
  let_it_be(:user) { create(:user) }

  let(:device_token) { SecureRandom.hex(32) }

  def register(user:, device_token:, apns_environment: 'production', attributes: {})
    described_class.new(
      user: user,
      device_token: device_token,
      apns_environment: apns_environment,
      attributes: attributes
    ).execute
  end

  describe '#execute' do
    it 'creates a new subscription with last_seen_at set' do
      response = register(user: user, device_token: device_token, attributes: { device_name: 'iPhone' })

      expect(response).to be_success
      subscription = response.payload[:subscription]
      expect(subscription).to be_persisted
      expect(subscription.user).to eq(user)
      expect(subscription.device_name).to eq('iPhone')
      expect(subscription.last_seen_at).to be_present
    end

    it 'updates the existing subscription for the same token and environment' do
      existing = create(:mobile_device_push_subscription, user: user, device_token: device_token)

      response = register(user: user, device_token: device_token, attributes: { app_version: '2.0.0' })

      expect(response).to be_success
      subscription = response.payload[:subscription]
      expect(subscription.id).to eq(existing.id)
      expect(subscription.reload.app_version).to eq('2.0.0')
    end

    it 'rejects reassignment when the new user is already at the cap' do
      other_user = create(:user)
      existing = create(:mobile_device_push_subscription, user: other_user, device_token: device_token)
      stub_const('Notifications::MobileDevicePushSubscription::MAX_SUBSCRIPTIONS_PER_USER', 1)
      create(:mobile_device_push_subscription, user: user)

      response = register(user: user, device_token: device_token)

      expect(response).to be_error
      expect(response.reason).to eq(:bad_request)
      expect(response.payload[:subscription].errors[:base]).to be_present
      expect(existing.reload.user).to eq(other_user)
    end

    it 'normalizes mixed-case tokens onto one row' do
      register(user: user, device_token: device_token.upcase)
      response = register(user: user, device_token: device_token)

      expect(Notifications::MobileDevicePushSubscription.with_device_token(device_token).count).to eq(1)
      expect(response.payload[:subscription].device_token).to eq(device_token)
    end

    it 'finds an existing lowercase row when re-registering with uppercase' do
      existing = create(:mobile_device_push_subscription, user: user, device_token: device_token)

      response = register(user: user, device_token: device_token.upcase)

      expect(response.payload[:subscription].id).to eq(existing.id)
    end

    it 'reassigns a token owned by another user' do
      other_user = create(:user)
      existing = create(:mobile_device_push_subscription, user: other_user, device_token: device_token)

      response = register(user: user, device_token: device_token)

      expect(response).to be_success
      expect(response.payload[:subscription].id).to eq(existing.id)
      expect(existing.reload.user).to eq(user)
    end

    it 'treats the same token in another environment as a separate subscription' do
      create(:mobile_device_push_subscription, user: user, device_token: device_token)

      response = register(user: user, device_token: device_token, apns_environment: 'sandbox')

      expect(response).to be_success
      expect(response.payload[:subscription]).to be_persisted
      expect(user.mobile_device_push_subscriptions.count).to eq(2)
    end

    it 'returns an error with the unpersisted record for an invalid token' do
      response = register(user: user, device_token: 'nope')

      expect(response).to be_error
      expect(response.reason).to eq(:bad_request)
      subscription = response.payload[:subscription]
      expect(subscription).not_to be_persisted
      expect(subscription.errors[:device_token]).to be_present
      expect(response.message).to include('Device token')
    end

    it 'updates the winning row after losing a concurrent-insert race' do
      existing = create(:mobile_device_push_subscription, user: create(:user), device_token: device_token)

      # Simulate the race: the initial lookup misses the row another request
      # just inserted, so the save hits the unique index and the retry looks
      # the row up again.
      lookups = 0
      allow(Notifications::MobileDevicePushSubscription)
        .to receive(:find_or_initialize_for_device).and_wrap_original do |original, token, environment|
          lookups += 1

          if lookups == 1
            Notifications::MobileDevicePushSubscription.new(device_token: token, apns_environment: environment)
          else
            original.call(token, environment)
          end
        end

      response = register(user: user, device_token: device_token)

      expect(response).to be_success
      expect(response.payload[:subscription].id).to eq(existing.id)
      expect(existing.reload.user).to eq(user)
    end
  end
end
