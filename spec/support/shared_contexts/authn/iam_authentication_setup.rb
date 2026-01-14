# frozen_string_literal: true

RSpec.shared_context 'with IAM authentication setup' do
  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_issuer) { iam_service_url }
  let(:iam_audience) { 'gitlab-rails' }
  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:kid) { 'test-key-id' }

  before do
    allow(Gitlab.config.authn.iam_service).to receive_messages(
      enabled: true,
      url: iam_service_url,
      audience: iam_audience
    )

    stub_iam_jwks_endpoint
  end

  def stub_iam_service_config(enabled:, url:, audience: 'gitlab')
    allow(Gitlab.config.authn.iam_service).to receive_messages(
      enabled: enabled,
      url: url,
      audience: audience
    )
  end

  def stub_iam_jwks_endpoint(public_key = private_key.public_key, url: iam_service_url, kid: self.kid)
    jwks_response = { 'keys' => [JWT::JWK.new(public_key, { use: 'sig', kid: kid }).export] }

    stub_request(:get, "#{url}/.well-known/jwks.json")
      .to_return(status: 200, body: jwks_response.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_jwks_endpoint_connection_error(url:, error:)
    stub_request(:get, "#{url}/.well-known/jwks.json").to_raise(error)
  end

  def create_iam_jwt(
    user:, issuer:, private_key:, kid:, scopes: [], expires_at: 1.hour.from_now, aud: nil,
    exclude_claims: [])
    aud ||= iam_audience

    payload = {
      sub: "user:#{user.id}",
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: expires_at.to_i,
      iss: issuer,
      aud: aud,
      scope: scopes
    }

    exclude_claims.each { |claim| payload.delete(claim.to_sym) }

    headers = { kid: kid }
    JWT.encode(payload, private_key, 'RS256', headers)
  end
end
