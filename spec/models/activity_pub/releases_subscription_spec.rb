# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::ReleasesSubscription, type: :model, feature_category: :release_orchestration do
  describe 'factory' do
    subject { build(:activity_pub_releases_subscription) }

    it { is_expected.to be_valid }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).optional(false) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:subscriber_url) }

    describe 'subscriber_url' do
      subject { build(:activity_pub_releases_subscription) }

      it { is_expected.to validate_uniqueness_of(:subscriber_url).case_insensitive.scoped_to([:project_id]) }
      it { is_expected.to allow_value("http://example.com/actor").for(:subscriber_url) }
      it { is_expected.not_to allow_values("I'm definitely not a URL").for(:subscriber_url) }
    end

    describe 'subscriber_inbox_url' do
      subject { build(:activity_pub_releases_subscription) }

      it { is_expected.to validate_uniqueness_of(:subscriber_inbox_url).case_insensitive.scoped_to([:project_id]) }
      it { is_expected.to allow_value("http://example.com/actor").for(:subscriber_inbox_url) }
      it { is_expected.not_to allow_values("I'm definitely not a URL").for(:subscriber_inbox_url) }
    end

    describe 'shared_inbox_url' do
      subject { build(:activity_pub_releases_subscription) }

      it { is_expected.to allow_value("http://example.com/actor").for(:shared_inbox_url) }
      it { is_expected.not_to allow_values("I'm definitely not a URL").for(:shared_inbox_url) }
    end

    describe 'payload' do
      it { is_expected.not_to allow_value("string").for(:payload) }
      it { is_expected.not_to allow_value(1.0).for(:payload) }

      it do
        is_expected.to allow_value({
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/actor#follow/1',
          type: 'Follow',
          actor: 'https://example.com/actor',
          object: 'http://localhost/user/project/-/releases'
        }).for(:payload)
      end
    end
  end

  describe '.find_by_project_and_subscriber' do
    let_it_be(:subscription) { create(:activity_pub_releases_subscription) }

    it 'returns a record if arguments match' do
      result = described_class.find_by_project_and_subscriber(subscription.project_id,
        subscription.subscriber_url)

      expect(result).to eq(subscription)
    end

    it 'returns a record if subscriber url matches case insensitively' do
      result = described_class.find_by_project_and_subscriber(subscription.project_id,
        subscription.subscriber_url.upcase)

      expect(result).to eq(subscription)
    end

    it 'returns nil if project and url do not match' do
      result = described_class.find_by_project_and_subscriber(0, 'I really should not exist')

      expect(result).to be(nil)
    end

    it 'returns nil if project does not match' do
      result = described_class.find_by_project_and_subscriber(0, subscription.subscriber_url)

      expect(result).to be(nil)
    end

    it 'returns nil if url does not match' do
      result = described_class.find_by_project_and_subscriber(subscription.project_id, 'I really should not exist')

      expect(result).to be(nil)
    end
  end
end
