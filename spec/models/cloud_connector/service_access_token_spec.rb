# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudConnector::ServiceAccessToken, type: :model, feature_category: :cloud_connector do
  let_it_be(:expired_token) { create(:service_access_token, :expired) }
  let_it_be(:active_token) {  create(:service_access_token, :active) }

  describe '.expired', :freeze_time do
    it 'selects all expired tokens' do
      expect(described_class.expired).to match_array([expired_token])
    end
  end

  describe '.active', :freeze_time do
    it 'selects all active tokens' do
      expect(described_class.active).to match_array([active_token])
    end
  end

  describe '#token' do
    subject(:service_access_token) { described_class.new }

    let(:token_value) { 'Abc' }

    it 'is encrypted' do
      service_access_token.token = token_value

      aggregate_failures do
        expect(service_access_token.encrypted_token_iv).to be_present
        expect(service_access_token.encrypted_token).to be_present
        expect(service_access_token.encrypted_token).not_to eq(token_value)
        expect(service_access_token.token).to eq(token_value)
      end
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:expires_at) }
    end
  end

  describe '#expired?' do
    it 'returns false for active token' do
      expect(active_token).not_to be_expired
    end

    it 'returns true for expired token' do
      expect(expired_token).to be_expired
    end
  end

  describe '#refresh_required?', :freeze_time do
    let_it_be(:active_long_lived_token) { create(:service_access_token, expires_at: 3.days.from_now) }
    let_it_be(:active_short_lived_token) { create(:service_access_token, expires_at: 1.day.from_now) }

    it 'returns false for a token that lives longer 2 days' do
      expect(active_long_lived_token.refresh_required?).to be false
    end

    it 'returns true for a token that expires within 2 days' do
      expect(active_short_lived_token.refresh_required?).to be true
    end

    it 'returns true for expired token' do
      expect(expired_token.refresh_required?).to be true
    end
  end
end
