# frozen_string_literal: true

# spec/lib/authn/tokens/jwt_spec.rb

require 'spec_helper'

RSpec.describe Authn::Tokens::Jwt, feature_category: :system_access do
  let_it_be(:job) { create(:ci_build) }
  let_it_be(:signing_key) { OpenSSL::PKey::RSA.new(2048) }
  let_it_be(:expire_time) { 1.hour.from_now }
  let_it_be(:token_prefix) { 'prefix-' }
  let_it_be(:subject_type) { ::Ci::Build }
  let_it_be(:custom_payload) { { foo: 'bar', test: 123 } }

  describe '.rsa_encode' do
    subject(:encoded_token) do
      described_class.rsa_encode(
        subject: job,
        signing_key: signing_key,
        expire_time: expire_time,
        token_prefix: token_prefix,
        custom_payload: custom_payload)
    end

    it 'creates a JWT token with prefix' do
      expect(encoded_token).to start_with(token_prefix)
    end

    it 'includes correct payload information' do
      token = encoded_token.delete_prefix(token_prefix)
      payload = JWT.decode(token, signing_key.public_key, true, algorithm: 'RS256').first

      expect(payload['sub']).to eq(GlobalID.create(job).to_s) # rubocop:disable Rails/SaveBang -- not related to ActiveRecord
      expect(payload['iss']).to eq(Settings.gitlab.host)
      expect(payload['aud']).to eq('gitlab-authz-token')
      expect(payload['exp']).to eq(expire_time.to_i)
      expect(payload['version']).to eq('0.1.0')
      expect(payload['foo']).to eq('bar')
      expect(payload['test']).to eq(123)
    end

    context 'with invalid subject' do
      let(:job) { nil }

      it 'raises InvalidSubjectForTokenError' do
        expect { encoded_token }.to raise_error(described_class::InvalidSubjectForTokenError)
      end
    end
  end

  describe '.rsa_decode' do
    let(:encoded_token) do
      described_class.rsa_encode(
        subject: job,
        signing_key: signing_key,
        expire_time: expire_time,
        token_prefix: token_prefix
      )
    end

    subject(:decoded_token) do
      described_class.rsa_decode(
        token: encoded_token,
        signing_public_key: signing_key.public_key,
        subject_type: subject_type,
        token_prefix: token_prefix
      )
    end

    it 'returns a Jwt instance' do
      expect(decoded_token).to be_a(described_class)
    end

    it 'correctly decodes the subject' do
      expect(decoded_token.subject).to eq(job)
    end

    context 'with invalid token' do
      let(:encoded_token) { 'invalid-token' }

      it { is_expected.to be_nil }
    end

    context 'with wrong prefix' do
      let(:encoded_token) { 'wrong-prefix-token' }

      it { is_expected.to be_nil }
    end

    context 'with expired token' do
      let(:expire_time) { 1.hour.ago }

      it { is_expected.to be_nil }
    end
  end

  describe '#subject' do
    let(:jwt) do
      described_class.new(
        payload: { 'sub' => GlobalID.create(job).to_s }, # rubocop:disable Rails/SaveBang -- not related to ActiveRecord
        subject_type: subject_type
      )
    end

    subject(:jwt_subject) { jwt.subject }

    it 'returns the correct subject' do
      expect(jwt_subject).to eq(job)
    end

    context 'with invalid payload' do
      let(:jwt) { described_class.new(payload: nil, subject_type: subject_type) }

      it { is_expected.to be_nil }
    end

    context 'with wrong subject type' do
      let(:subject_type) { Project }

      it { is_expected.to be_nil }
    end
  end
end
