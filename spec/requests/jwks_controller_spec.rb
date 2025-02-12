# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JwksController, feature_category: :system_access do
  describe 'Endpoints from the parent Doorkeeper::OpenidConnect::DiscoveryController' do
    it 'respond successfully' do
      [
        "/oauth/discovery/keys",
        "/.well-known/openid-configuration",
        "/.well-known/webfinger?resource=#{create(:user).email}"
      ].each do |endpoint|
        get endpoint

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe '/oauth/discovery/keys' do
    include_context 'when doing OIDC key discovery'

    it 'removes missing keys' do
      expect(Rails.application.credentials).to receive(:openid_connect_signing_key).and_return(rsa_key_1.to_pem)
      expect(Gitlab::CurrentSettings).to receive(:ci_jwt_signing_key).and_return(nil)

      expect(jwks.size).to eq(1)
      expect(jwks).to match_array([
        satisfy { |jwk| key_match?(jwk, rsa_key_1) }
      ])
    end

    it 'removes duplicate keys' do
      expect(Rails.application.credentials).to receive(:openid_connect_signing_key).and_return(rsa_key_1.to_pem)
      expect(Gitlab::CurrentSettings).to receive(:ci_jwt_signing_key).and_return(rsa_key_1.to_pem)

      expect(jwks.size).to eq(1)
      expect(jwks).to match_array([
        satisfy { |jwk| key_match?(jwk, rsa_key_1) }
      ])
    end
  end
end
