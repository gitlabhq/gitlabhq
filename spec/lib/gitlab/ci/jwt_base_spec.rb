# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::JwtBase, :freeze_time, feature_category: :secrets_management do
  let(:key) { OpenSSL::PKey::RSA.generate(3072) }
  let(:key_data) { key.to_s }
  let(:kid) { key.public_key.to_jwk[:kid] }
  let(:headers) { { kid: kid, typ: 'JWT' } }
  let(:now) { Time.zone.now.to_i }
  let(:uuid) { SecureRandom.uuid }

  let(:default_payload) do
    {
      jti: uuid,
      iat: now,
      nbf: now - described_class::DEFAULT_NOT_BEFORE_TIME,
      exp: now + described_class::DEFAULT_EXPIRE_TIME
    }
  end

  before do
    stub_application_setting(ci_jwt_signing_key: key_data)
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
  end

  shared_examples 'raises NoSigningKeyError' do
    it do
      expect { subject }.to raise_error(described_class::NoSigningKeyError)
    end
  end

  describe '.decode' do
    let(:token) { described_class.new.encoded }

    subject(:decoded) { described_class.decode(token, key) }

    it 'decodes the JWT' do
      expect(decoded[0]).to include(default_payload.stringify_keys)
      expect(decoded[1]).to include({ 'alg' => ::JSONWebToken::RSAToken::ALGORITHM }.merge(headers.stringify_keys))
    end

    context 'when signing key is missing' do
      let(:key_data) { nil }

      it_behaves_like 'raises NoSigningKeyError'
    end
  end

  describe '#encoded' do
    subject(:encoded) { described_class.new.encoded }

    it 'generates the JWT' do
      expect(OpenSSL::PKey::RSA).to receive(:new).and_return(key)
      expect(::JSONWebToken::RSAToken).to receive(:encode).with(default_payload, key, kid).and_call_original

      expect(encoded).to be_a(String)
    end

    context 'when signing key is missing' do
      let(:key_data) { nil }

      it_behaves_like 'raises NoSigningKeyError'
    end
  end

  describe '#payload' do
    let(:jwt_token) { described_class.new }

    subject(:payload) { jwt_token.payload }

    before do
      jwt_token['key'] = 'value'
    end

    it 'includes custom payload' do
      expect(payload).to include('key' => 'value')
    end

    it 'includes default payload' do
      expect(payload).to include(default_payload)
    end
  end
end
