# frozen_string_literal: true

RSpec.shared_context 'with IAM authentication setup' do
  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_issuer) { iam_service_url }
  let(:iam_audience) { 'gitlab-rails' }
  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:kid) { 'test-key-id' }

  before do
    stub_iam_service_config(enabled: true, url: iam_service_url, audience: iam_audience)
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

  def create_iam_jwt(user:, issuer:, private_key:, kid:, **options)
    scopes = options.fetch(:scopes, [])
    expires_at = options.fetch(:expires_at, 1.hour.from_now)
    issued_at = options.fetch(:issued_at, Time.current)
    aud = options.fetch(:aud, iam_audience)
    sub = options.fetch(:sub, user.id.to_s)
    exclude_claims = options.fetch(:exclude_claims, [])

    payload = {
      sub: sub,
      jti: SecureRandom.uuid,
      iat: issued_at.to_i,
      exp: expires_at.to_i,
      iss: issuer,
      aud: aud,
      scope: scopes
    }

    exclude_claims.each { |claim| payload.delete(claim.to_sym) }

    headers = { kid: kid }
    JWT.encode(payload, private_key, 'RS256', headers)
  end

  def stub_iam_jwks_key_rotation(old_key:, new_key:, url: nil, kid: nil)
    url ||= iam_service_url
    kid ||= self.kid

    old_jwks = { 'keys' => [JWT::JWK.new(old_key.public_key, { use: 'sig', kid: kid }).export] }
    new_jwks = { 'keys' => [JWT::JWK.new(new_key.public_key, { use: 'sig', kid: kid }).export] }

    # Simulate key rotation: first call returns old key, second call returns new key
    stub_request(:get, "#{url}/.well-known/jwks.json")
      .to_return(
        { status: 200, body: old_jwks.to_json, headers: { 'Content-Type' => 'application/json' } },
        { status: 200, body: new_jwks.to_json, headers: { 'Content-Type' => 'application/json' } }
      )
  end
end
