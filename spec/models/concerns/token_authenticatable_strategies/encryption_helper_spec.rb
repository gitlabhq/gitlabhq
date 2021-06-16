# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatableStrategies::EncryptionHelper do
  let(:encrypted_token) { described_class.encrypt_token('my-value-my-value-my-value') }

  describe '.encrypt_token' do
    context 'when dynamic_nonce feature flag is switched on' do
      it 'adds nonce identifier on the beginning' do
        expect(encrypted_token.first).to eq(described_class::DYNAMIC_NONCE_IDENTIFIER)
      end

      it 'adds nonce at the end' do
        nonce = encrypted_token.last(described_class::NONCE_SIZE)

        expect(nonce).to eq(::Digest::SHA256.hexdigest('my-value-my-value-my-value').bytes.take(described_class::NONCE_SIZE).pack('c*'))
      end

      it 'encrypts token' do
        expect(encrypted_token[1...-described_class::NONCE_SIZE]).not_to eq('my-value-my-value-my-value')
      end
    end

    context 'when dynamic_nonce feature flag is switched off' do
      before do
        stub_feature_flags(dynamic_nonce: false)
      end

      it 'does not add nonce identifier on the beginning' do
        expect(encrypted_token.first).not_to eq(described_class::DYNAMIC_NONCE_IDENTIFIER)
      end

      it 'does not add nonce in the end' do
        nonce = encrypted_token.last(described_class::NONCE_SIZE)

        expect(nonce).not_to eq(::Digest::SHA256.hexdigest('my-value-my-value-my-value').bytes.take(described_class::NONCE_SIZE).pack('c*'))
      end

      it 'encrypts token with static iv' do
        token = Gitlab::CryptoHelper.aes256_gcm_encrypt('my-value-my-value-my-value')

        expect(encrypted_token).to eq(token)
      end
    end
  end

  describe '.decrypt_token' do
    context 'with feature flag switched off' do
      before do
        stub_feature_flags(dynamic_nonce: false)
      end

      it 'decrypts token with static iv' do
        encrypted_token = described_class.encrypt_token('my-value')

        expect(described_class.decrypt_token(encrypted_token)).to eq('my-value')
      end

      it 'decrypts token if feature flag changed after encryption' do
        encrypted_token = described_class.encrypt_token('my-value')

        expect(encrypted_token).not_to eq('my-value')

        stub_feature_flags(dynamic_nonce: true)

        expect(described_class.decrypt_token(encrypted_token)).to eq('my-value')
      end

      it 'decrypts token with dynamic iv' do
        iv = ::Digest::SHA256.hexdigest('my-value').bytes.take(described_class::NONCE_SIZE).pack('c*')
        token = Gitlab::CryptoHelper.aes256_gcm_encrypt('my-value', nonce: iv)
        encrypted_token = "#{described_class::DYNAMIC_NONCE_IDENTIFIER}#{token}#{iv}"

        expect(described_class.decrypt_token(encrypted_token)).to eq('my-value')
      end
    end

    context 'with feature flag switched on' do
      before do
        stub_feature_flags(dynamic_nonce: true)
      end

      it 'decrypts token with dynamic iv' do
        encrypted_token = described_class.encrypt_token('my-value')

        expect(described_class.decrypt_token(encrypted_token)).to eq('my-value')
      end

      it 'decrypts token if feature flag changed after encryption' do
        encrypted_token = described_class.encrypt_token('my-value')

        expect(encrypted_token).not_to eq('my-value')

        stub_feature_flags(dynamic_nonce: false)

        expect(described_class.decrypt_token(encrypted_token)).to eq('my-value')
      end
    end
  end
end
