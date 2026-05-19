# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthConsent, feature_category: :system_access do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:application).class_name('Authn::OauthApplication') }
  end

  describe 'validations' do
    subject(:consent) { build(:oauth_consent) }

    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_presence_of(:consent_challenge) }

    it 'validates uniqueness of consent_challenge' do
      create(:oauth_consent, consent_challenge: consent.consent_challenge)
      is_expected.to validate_uniqueness_of(:consent_challenge)
    end

    context 'when consent is revoked' do
      subject(:consent) { create(:oauth_consent, :revoked) }

      it 'prevents any update' do
        consent.status = 'authorized'
        expect(consent).not_to be_valid
        expect(consent.errors[:status]).to include('revoked consent cannot be modified')
      end
    end

    context 'when consent is authorized' do
      subject(:consent) { create(:oauth_consent) }

      it 'allows updates' do
        consent.granted_scopes = %w[openid]
        expect(consent).to be_valid
      end
    end
  end
end
