# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatableStrategies::EncryptionHelper do
  let(:encrypted_token) { described_class.encrypt_token('my-value') }

  describe '.encrypt_token' do
    it 'encrypts token' do
      expect(encrypted_token).not_to eq('my-value')
    end
  end

  describe '.decrypt_token' do
    it 'decrypts token with static iv' do
      expect(described_class.decrypt_token(encrypted_token)).to eq('my-value')
    end

    it 'decrypts token with dynamic iv' do
      iv = ::Digest::SHA256.hexdigest('my-value').bytes.take(described_class::NONCE_SIZE).pack('c*')
      token = Gitlab::CryptoHelper.aes256_gcm_encrypt('my-value', nonce: iv)
      encrypted_token = "#{described_class::DYNAMIC_NONCE_IDENTIFIER}#{token}#{iv}"

      expect(described_class.decrypt_token(encrypted_token)).to eq('my-value')
    end
  end
end
