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
  end

  describe '.matching_token_for' do
    it 'does not find existing tokens' do
      expect(described_class.matching_token_for(app_one, token.resource_owner, token.scopes)).to be_nil
    end
  end

  describe '#expires_in' do
    context 'when token has expires_in value set' do
      it 'uses the expires_in value' do
        token = OauthAccessToken.new(expires_in: 1.minute)

        expect(token).to be_valid
      end
    end

    context 'when token has nil expires_in' do
      it 'uses default value' do
        token = OauthAccessToken.new(expires_in: nil)

        expect(token).to be_invalid
      end
    end
  end
end
