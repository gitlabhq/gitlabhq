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

  describe '.subscribed_user_ids' do
    let_it_be(:user) { create(:user) }
    let_it_be(:unsubscribed_user) { create(:user) }

    it 'returns the distinct given user ids that have a subscription' do
      create_list(:mobile_device_push_subscription, 2, user: user)

      ids = described_class.subscribed_user_ids([user.id, unsubscribed_user.id, non_existing_record_id])

      expect(ids).to contain_exactly(user.id)
    end

    it 'returns an empty array when no given user has a subscription' do
      expect(described_class.subscribed_user_ids([unsubscribed_user.id])).to be_empty
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
