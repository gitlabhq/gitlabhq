# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Token fallback strategies", feature_category: :system_access do
  let(:plaintext_token_value) { 'CzOBzBfU9F-HvsqfTaTXF4ivuuxYZuv3BoAK4pnvmyw' }

  it 'works with plain token' do
    plaintext_token = create(:oauth_access_token)
    plaintext_token.update_column(:token, plaintext_token_value)

    expect(OauthAccessToken.by_token(plaintext_token_value)).to be_truthy
  end

  it "works with PBKDF2+SHA512 token" do
    pbkdf_token = create(:oauth_access_token)
    value = Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512.transform_secret(plaintext_token_value)
    pbkdf_token.update_column(:token, value)
    expect(OauthAccessToken.by_token(plaintext_token_value)).to be_truthy
  end

  it "works with SHA512 token" do
    sha512_token = create(:oauth_access_token)
    value = Gitlab::DoorkeeperSecretStoring::Sha512Hash.transform_secret(plaintext_token_value)
    sha512_token.update_column(:token, value)
    expect(OauthAccessToken.by_token(plaintext_token_value)).to be_truthy
  end
end
