# frozen_string_literal: true

RSpec.shared_context 'with IAM authentication setup' do
  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_issuer) { iam_service_url }
  let(:iam_audience) { 'gitlab-rails' }
  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:kid) { 'test-key-id' }

  before do
    stub_iam_service_config(enabled: true, url: iam_service_url, jwt_audience: iam_audience,
      jwt_issuer: iam_issuer)
    stub_iam_jwks_endpoint
  end

  def stub_iam_service_config(enabled:, url:, jwt_audience: 'gitlab-rails', jwt_issuer: nil)
    allow(Authn::IamAuthService).to receive_messages(
      enabled?: enabled,
      url: url,
      jwt_audience: jwt_audience,
      jwt_issuer: jwt_issuer,
      secret: nil
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
    algorithm = options.fetch(:algorithm, 'RS256')

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

    JWT.encode(payload, private_key, algorithm, { kid: kid })
  end
end
