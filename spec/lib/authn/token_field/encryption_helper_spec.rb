# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::TokenField::EncryptionHelper, feature_category: :system_access do
  let(:encrypted_token) { described_class.encrypt_token('my-value-my-value-my-value') }

  describe '.encrypt_token' do
    it 'adds nonce identifier on the beginning' do
      expect(encrypted_token.first).to eq(described_class::DYNAMIC_NONCE_IDENTIFIER)
    end

    it 'adds nonce at the end' do
      nonce = encrypted_token.last(described_class::NONCE_SIZE)

      expect(nonce).to eq(
        ::Digest::SHA256.hexdigest('my-value-my-value-my-value').bytes.take(described_class::NONCE_SIZE).pack('c*')
      )
    end

    it 'encrypts token' do
      expect(encrypted_token[1...-described_class::NONCE_SIZE]).not_to eq('my-value-my-value-my-value')
    end
  end

  describe '.decrypt_token' do
    it 'decrypts token with dynamic iv' do
      encrypted_token = described_class.encrypt_token('my-value')

      expect(described_class.decrypt_token(encrypted_token)).to eq('my-value')
    end
  end
end
