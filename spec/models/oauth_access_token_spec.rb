# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OauthAccessToken do
  let(:app_one) { create(:oauth_application) }
  let(:app_two) { create(:oauth_application) }
  let(:app_three) { create(:oauth_application) }
  let(:token) { create(:oauth_access_token, application_id: app_one.id) }

  describe 'scopes' do
    describe '.latest_per_application' do
      let!(:app_two_token1) { create(:oauth_access_token, application: app_two) }
      let!(:app_two_token2) { create(:oauth_access_token, application: app_two) }
      let!(:app_three_token1) { create(:oauth_access_token, application: app_three) }
      let!(:app_three_token2) { create(:oauth_access_token, application: app_three) }

      it 'returns only the latest token for each application' do
        expect(described_class.latest_per_application.map(&:id))
          .to match_array([app_two_token2.id, app_three_token2.id])
      end
    end
  end

  describe 'Doorkeeper secret storing' do
    it 'stores the token in hashed format' do
      expect(token.token).not_to eq(token.plaintext_token)
    end

    it 'does not allow falling back to plaintext token comparison' do
      expect(described_class.by_token(token.token)).to be_nil
    end

    it 'finds a token by plaintext token' do
      expect(described_class.by_token(token.plaintext_token)).to be_a(OauthAccessToken)
    end

    context 'when the token is stored in plaintext' do
      let(:plaintext_token) { Devise.friendly_token(20) }

      before do
        token.update_column(:token, plaintext_token)
      end

      it 'falls back to plaintext token comparison' do
        expect(described_class.by_token(plaintext_token)).to be_a(OauthAccessToken)
      end
    end

    context 'when hash_oauth_secrets is disabled' do
      let(:hashed_token) { create(:oauth_access_token, application_id: app_one.id) }

      before do
        hashed_token
        stub_feature_flags(hash_oauth_tokens: false)
      end

      it 'stores the token in plaintext' do
        expect(token.token).to eq(token.plaintext_token)
      end

      it 'finds a token by plaintext token' do
        expect(described_class.by_token(token.plaintext_token)).to be_a(OauthAccessToken)
      end

      it 'does not find a token that was previously stored as hashed' do
        expect(described_class.by_token(hashed_token.plaintext_token)).to be_nil
      end
    end
  end

  describe '.matching_token_for' do
    it 'does not find existing tokens' do
      expect(described_class.matching_token_for(app_one, token.resource_owner, token.scopes)).to be_nil
    end

    context 'when hash oauth tokens is disabled' do
      before do
        stub_feature_flags(hash_oauth_tokens: false)
      end

      it 'finds an existing token' do
        expect(described_class.matching_token_for(app_one, token.resource_owner, token.scopes)).to be_present
      end
    end
  end
end
