# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::Forge::InvocationToken, feature_category: :integrations do
  let(:rsa_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:kid) { 'forge-test-kid' }
  let(:audience) { 'ari:cloud:ecosystem::app/00000000-0000-0000-0000-000000000000' }

  let(:claims) do
    {
      iss: described_class::ISSUER,
      aud: audience,
      exp: 1.hour.from_now.to_i,
      principal: 'jira-account-id-123',
      app: {
        id: audience,
        installationId: 'forge-installation-id',
        module: { type: 'jira:adminPage', key: 'gitlab-configuration' }
      },
      context: { cloudId: 'jira-cloud-id-abc' }
    }
  end

  let(:raw_token) { JWT.encode(claims, rsa_key, described_class::ALGORITHM, { kid: kid }) }
  let(:jwks_client) { instance_double(Atlassian::Forge::JwksClient) }

  subject(:token) { described_class.new(raw_token, audience: audience, jwks_client: jwks_client) }

  before do
    allow(jwks_client).to receive(:verification_key_for).with(kid).and_return(rsa_key.public_key)
  end

  describe '#valid? and claim accessors' do
    it 'verifies the signature and exposes the claims', :aggregate_failures do
      expect(token).to be_valid
      expect(token).to have_attributes(
        installation_id: 'forge-installation-id',
        cloud_id: 'jira-cloud-id-abc',
        app_id: audience,
        module_type: 'jira:adminPage',
        module_key: 'gitlab-configuration',
        principal: 'jira-account-id-123'
      )
    end
  end

  describe 'invalid tokens' do
    context 'with a tampered signature' do
      let(:other_key) { OpenSSL::PKey::RSA.new(2048) }
      let(:raw_token) { JWT.encode(claims, other_key, described_class::ALGORITHM, { kid: kid }) }

      it { is_expected.not_to be_valid }
    end

    context 'when expired' do
      let(:claims) { super().merge(exp: 1.hour.ago.to_i) }

      it { is_expected.not_to be_valid }
    end

    context 'with the wrong issuer' do
      let(:claims) { super().merge(iss: 'someone-else') }

      it { is_expected.not_to be_valid }
    end

    context 'with the wrong audience' do
      let(:claims) { super().merge(aud: 'ari:cloud:ecosystem::app/other') }

      it { is_expected.not_to be_valid }
    end

    context 'when audience verification is disabled (blank audience)' do
      subject(:token) { described_class.new(raw_token, audience: nil, jwks_client: jwks_client) }

      let(:claims) { super().merge(aud: 'ari:cloud:ecosystem::app/anything') }

      it 'still verifies signature, issuer and expiry but skips audience' do
        expect(token).to be_valid
      end
    end

    context 'when the signing key is unknown' do
      before do
        allow(jwks_client).to receive(:verification_key_for)
          .and_raise(Atlassian::Forge::JwksClient::KeyNotFoundError)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it { is_expected.not_to be_valid }
    end

    context 'when the token is not a JWT' do
      let(:raw_token) { 'not-a-jwt' }

      it { is_expected.not_to be_valid }
    end
  end
end
