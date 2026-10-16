# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OrgMover::Authenticator, feature_category: :organization do
  let(:public_key_path) { '/path/to/org_mover_public_key.pem' }
  let(:public_key_files) { [public_key_path] }
  let(:private_key) { OpenSSL::PKey::EC.generate('prime256v1') }
  let(:public_key) { OpenSSL::PKey::EC.new(private_key.public_to_pem) }

  let(:audience) { "#{described_class::JWT_AUDIENCE}:cell-2" }

  let(:payload) do
    { iss: described_class::JWT_ISSUER, aud: audience, iat: Time.current.to_i }
  end

  let(:token) { es256_token(private_key) }
  let(:headers) { { described_class::API_HEADER => token } }

  before do
    stub_config_cell(enabled: true, id: 2)
    stub_config(org_mover: { public_key_files: public_key_files })
    allow(described_class).to receive(:read_public_key).with(public_key_path).and_return(public_key)
    described_class.clear_memoization(:jwks)
  end

  after do
    described_class.clear_memoization(:jwks)
  end

  def es256_token(key, data: payload, kid: JWT::JWK.new(key, kid_generator: JWT::JWK::Thumbprint).kid)
    JWT.encode(data, key, 'ES256', { kid: kid })
  end

  describe '.verify_api_request' do
    subject(:verify) { described_class.verify_api_request(headers) }

    it 'returns the decoded token', :aggregate_failures do
      decoded_payload, header = verify

      expect(decoded_payload).to include('iss' => described_class::JWT_ISSUER, 'aud' => audience)
      expect(header).to include('alg' => 'ES256')
    end

    context 'when several public keys are configured' do
      let(:new_private_key) { OpenSSL::PKey::EC.generate('prime256v1') }
      let(:new_public_key_path) { '/path/to/new_org_mover_public_key.pem' }
      let(:public_key_files) { [public_key_path, new_public_key_path] }
      let(:token) { es256_token(new_private_key) }

      before do
        allow(described_class).to receive(:read_public_key)
          .with(new_public_key_path).and_return(OpenSSL::PKey::EC.new(new_private_key.public_to_pem))
      end

      it 'accepts a token signed by any of them' do
        expect(verify).to be_present
      end
    end

    context 'without the header' do
      let(:headers) { {} }

      it { is_expected.to be_nil }
    end

    context 'without configured public keys' do
      let(:public_key_files) { [] }

      it { is_expected.to be_nil }
    end

    context 'with a kid that is not the RFC 7638 thumbprint' do
      let(:token) { es256_token(private_key, kid: JWT::JWK.new(public_key).key_digest) }

      it { is_expected.to be_nil }
    end

    context 'with characters inserted into the signature' do
      let(:token) do
        header, claims, signature = es256_token(private_key).split('.')

        [header, claims, signature.insert(10, '!!!')].join('.')
      end

      it { is_expected.to be_nil }
    end

    context 'with a token that is too long' do
      let(:token) { es256_token(private_key, data: payload.merge(padding: 'a' * described_class::MAX_TOKEN_LENGTH)) }

      it { is_expected.to be_nil }
    end

    context 'with a token that is not a string' do
      let(:headers) { { described_class::API_HEADER => [es256_token(private_key)] } }

      it { is_expected.to be_nil }
    end

    context 'with a token signed by an untrusted key' do
      let(:token) { es256_token(OpenSSL::PKey::EC.generate('prime256v1')) }

      it { is_expected.to be_nil }
    end

    context 'with an HS256 token' do
      let(:token) { JWT.encode(payload, SecureRandom.random_bytes(32), 'HS256') }

      it { is_expected.to be_nil }
    end

    context 'with the wrong issuer' do
      let(:token) { es256_token(private_key, data: payload.merge(iss: 'gitlab-shell')) }

      it { is_expected.to be_nil }
    end

    context 'with the wrong audience' do
      let(:token) { es256_token(private_key, data: payload.merge(aud: 'gitlab')) }

      it { is_expected.to be_nil }
    end

    context 'with a token for another cell' do
      let(:token) { es256_token(private_key, data: payload.merge(aud: "#{described_class::JWT_AUDIENCE}:cell-3")) }

      it { is_expected.to be_nil }
    end

    context 'with a token for several cells' do
      let(:token) do
        es256_token(private_key, data: payload.merge(aud: [audience, "#{described_class::JWT_AUDIENCE}:cell-3"]))
      end

      it { is_expected.to be_nil }
    end

    context 'with a token without a cell' do
      let(:token) { es256_token(private_key, data: payload.merge(aud: described_class::JWT_AUDIENCE)) }

      it { is_expected.to be_nil }
    end

    context 'when cells are disabled' do
      let(:audience) { "#{described_class::JWT_AUDIENCE}:cell-" }

      before do
        stub_config_cell(enabled: false, id: nil)
      end

      it { is_expected.to be_nil }
    end

    context 'without an iat claim' do
      let(:token) { es256_token(private_key, data: payload.except(:iat)) }

      it { is_expected.to be_nil }
    end

    context 'with an iat in the future within the clock skew' do
      let(:token) { es256_token(private_key, data: payload.merge(iat: (Time.current + 10.seconds).to_i)) }

      it { is_expected.to be_present }
    end

    context 'with an iat further in the future than the clock skew' do
      let(:token) do
        es256_token(private_key, data: payload.merge(iat: (Time.current + described_class::CLOCK_SKEW + 1.second).to_i))
      end

      it { is_expected.to be_nil }
    end

    context 'with an iat older than the expiration window' do
      let(:token) do
        es256_token(private_key, data: payload.merge(iat: (Time.current - described_class::EXPIRATION - 1.second).to_i))
      end

      it { is_expected.to be_nil }
    end
  end
end
