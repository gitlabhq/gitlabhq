# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notifications::MobileDevicePushSubscription, feature_category: :notifications do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:mobile_device_push_subscription) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:device_token) }
    it { is_expected.to allow_value(SecureRandom.hex(32)).for(:device_token) }
    it { is_expected.to allow_value('A' * 16).for(:device_token) }
    it { is_expected.not_to allow_value('not-a-hex-token!').for(:device_token) }
    it { is_expected.not_to allow_value('abcdef').for(:device_token) }
    it { is_expected.not_to allow_value('a' * 201).for(:device_token) }

    describe 'subscriptions cap per user' do
      let_it_be(:user) { create(:user) }

      it 'rejects new subscriptions once the user reached the cap' do
        create(:mobile_device_push_subscription, user: user)
        stub_const("#{described_class}::MAX_SUBSCRIPTIONS_PER_USER", 1)

        subscription = build(:mobile_device_push_subscription, user: user)

        expect(subscription).not_to be_valid
        expect(subscription.errors[:base])
          .to include('cannot have more than 1 push subscriptions per user')
      end

      it 'does not apply the cap when updating an existing subscription' do
        subscription = create(:mobile_device_push_subscription, user: user)
        stub_const("#{described_class}::MAX_SUBSCRIPTIONS_PER_USER", 1)

        subscription.last_seen_at = Time.current

        expect(subscription).to be_valid
      end
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:platform).with_values(ios: 0) }
    it { is_expected.to define_enum_for(:apns_environment).with_values(production: 0, sandbox: 1).with_prefix(:apns) }
    it { is_expected.to define_enum_for(:payload_mode).with_values(full: 0, id_only: 1).with_suffix(:payload) }
  end

  describe '.register' do
    let_it_be(:user) { create(:user) }

    let(:device_token) { SecureRandom.hex(32) }

    it 'creates a new subscription with last_seen_at set' do
      subscription = described_class.register(
        user: user,
        device_token: device_token,
        apns_environment: 'production',
        attributes: { device_name: 'iPhone' }
      )

      expect(subscription).to be_persisted
      expect(subscription.user).to eq(user)
      expect(subscription.device_name).to eq('iPhone')
      expect(subscription.last_seen_at).to be_present
    end

    it 'updates the existing subscription for the same token and environment' do
      existing = create(:mobile_device_push_subscription, user: user, device_token: device_token)

      subscription = described_class.register(
        user: user,
        device_token: device_token,
        apns_environment: 'production',
        attributes: { app_version: '2.0.0' }
      )

      expect(subscription.id).to eq(existing.id)
      expect(subscription.reload.app_version).to eq('2.0.0')
    end

    it 'rejects reassignment when the new user is already at the cap' do
      other_user = create(:user)
      existing = create(:mobile_device_push_subscription, user: other_user, device_token: device_token)
      stub_const("#{described_class}::MAX_SUBSCRIPTIONS_PER_USER", 1)
      create(:mobile_device_push_subscription, user: user)

      subscription = described_class.register(
        user: user,
        device_token: device_token,
        apns_environment: 'production'
      )

      expect(subscription.errors[:base]).to be_present
      expect(existing.reload.user).to eq(other_user)
    end

    it 'normalizes mixed-case tokens onto one row' do
      described_class.register(
        user: user, device_token: device_token.upcase, apns_environment: 'production'
      )
      subscription = described_class.register(
        user: user, device_token: device_token, apns_environment: 'production'
      )

      expect(described_class.with_device_token(device_token).count).to eq(1)
      expect(subscription.device_token).to eq(device_token)
    end

    it 'finds an existing lowercase row when re-registering with uppercase' do
      existing = create(:mobile_device_push_subscription, user: user, device_token: device_token)

      subscription = described_class.register(
        user: user, device_token: device_token.upcase, apns_environment: 'production'
      )

      expect(subscription.id).to eq(existing.id)
    end

    it 'reassigns a token owned by another user' do
      other_user = create(:user)
      existing = create(:mobile_device_push_subscription, user: other_user, device_token: device_token)

      subscription = described_class.register(
        user: user,
        device_token: device_token,
        apns_environment: 'production'
      )

      expect(subscription.id).to eq(existing.id)
      expect(subscription.reload.user).to eq(user)
    end

    it 'treats the same token in another environment as a separate subscription' do
      create(:mobile_device_push_subscription, user: user, device_token: device_token)

      subscription = described_class.register(
        user: user,
        device_token: device_token,
        apns_environment: 'sandbox'
      )

      expect(subscription).to be_persisted
      expect(user.mobile_device_push_subscriptions.count).to eq(2)
    end

    it 'returns an unpersisted record with errors for an invalid token' do
      subscription = described_class.register(
        user: user,
        device_token: 'nope',
        apns_environment: 'production'
      )

      expect(subscription).not_to be_persisted
      expect(subscription.errors[:device_token]).to be_present
    end

    it 'updates the winning row after losing a concurrent-insert race' do
      existing = create(:mobile_device_push_subscription, user: create(:user), device_token: device_token)

      # Simulate the race: the initial lookup misses the row another request
      # just inserted, so the save hits the unique index and the retry looks
      # the row up again.
      lookups = 0
      allow(described_class).to receive(:find_or_initialize_by).and_wrap_original do |original, attrs|
        lookups += 1
        lookups == 1 ? described_class.new(attrs) : original.call(attrs)
      end

      subscription = described_class.register(
        user: user,
        device_token: device_token,
        apns_environment: 'production'
      )

      expect(subscription.id).to eq(existing.id)
      expect(existing.reload.user).to eq(user)
    end
  end

  describe '.stale' do
    let_it_be(:user) { create(:user) }

    it 'returns subscriptions last seen before the cutoff' do
      stale = create(:mobile_device_push_subscription, user: user, last_seen_at: 91.days.ago)
      create(:mobile_device_push_subscription, user: user, last_seen_at: 89.days.ago)
      create(:mobile_device_push_subscription, user: user)

      expect(described_class.stale(90.days.ago)).to contain_exactly(stale)
    end

    it 'fills last_seen_at from the database default when not set explicitly' do
      subscription = create(:mobile_device_push_subscription, user: user)

      expect(subscription.reload.last_seen_at).to be_present
    end
  end

  describe 'device token encryption' do
    it 'stores the token encrypted and decrypts it transparently' do
      token = SecureRandom.hex(32)
      subscription = create(:mobile_device_push_subscription, device_token: token)

      expect(subscription.reload.device_token).to eq(token)
      expect(subscription.ciphertext_for(:device_token)).not_to include(token)
    end

    it 'finds rows by plaintext token through the encrypted column' do
      subscription = create(:mobile_device_push_subscription)

      expect(described_class.with_device_token(subscription.device_token)).to contain_exactly(subscription)
    end
  end

  describe 'device token normalization' do
    it 'lowercases tokens on assignment' do
      expect(described_class.normalize_value_for(:device_token, 'ABCDEF1234567890')).to eq('abcdef1234567890')
    end
  end
end
