# frozen_string_literal: true

require 'spec_helper'

# Guards against Authn::IamService::UserinfoClaimsBuilder drifting out of
# sync with the real OIDC ID token claims defined in
# config/initializers/doorkeeper_openid_connect.rb. If a claim is added,
# removed, renamed, or its computation changes there, this spec fails until
# UserinfoClaimsBuilder is updated to match. This only applies to claims with
# the response: [:user_info] attribute in doorkeeper_openid_connect.
RSpec.describe 'OIDC ID token / IAM userinfo claim parity', feature_category: :system_access do
  let_it_be(:application) { create(:oauth_application) }

  let(:user) do
    create(:user,
      name: 'Alice',
      username: 'alice',
      website_url: 'https://example.com',
      first_name: 'Alice',
      last_name: 'Smith',
      current_sign_in_at: Time.current
    )
  end

  let(:access_token) do
    create(:oauth_access_token, resource_owner: user, application: application, scopes: 'openid')
  end

  # Doorkeeper computes these with OAuth-scope-gated public/private email
  # visibility, which doesn't apply to the IAM-token flow (the token
  # authenticates the user directly, not a third-party app's granted
  # scopes) -- see app/services/authn/iam_service/userinfo_claims_builder.rb.
  let(:intentionally_divergent_claims) { %w[email email_verified] }

  # JWT/OAuth mechanics present on the real ID token that aren't "shared
  # information" user claims and aren't part of the IAM userinfo response.
  let(:token_mechanics_claims) { %w[iss aud exp iat nonce sub_legacy] }

  let(:id_token_claims) do
    Doorkeeper::OpenidConnect::IdToken.new(access_token).claims.stringify_keys.except(*token_mechanics_claims)
  end

  let(:iam_claims) { Authn::IamService::UserinfoClaimsBuilder.new(user).claims.stringify_keys }

  before do
    email = create(:email, :confirmed, email: 'public@example.com', user: user)
    user.update!(public_email: email.email)
  end

  it 'exposes exactly the same claim keys as the real ID token' do
    expect(iam_claims.keys).to match_array(id_token_claims.keys)
  end

  it 'computes the same values as the real ID token, except the intentionally divergent email claims' do
    (id_token_claims.keys - intentionally_divergent_claims).each do |claim|
      expect(iam_claims[claim]).to eq(id_token_claims[claim]), "claim #{claim.inspect} diverged from the real ID token"
    end
  end
end
