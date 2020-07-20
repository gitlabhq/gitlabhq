# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CryptoHelper do
  describe '.sha256' do
    it 'generates SHA256 digest Base46 encoded' do
      digest = described_class.sha256('some-value')

      expect(digest).to match %r{\A[A-Za-z0-9+/=]+\z}
      expect(digest).to eq digest.strip
    end
  end

  describe '.aes256_gcm_encrypt' do
    it 'is Base64 encoded string without new line character' do
      encrypted = described_class.aes256_gcm_encrypt('some-value')

      expect(encrypted).to match %r{\A[A-Za-z0-9+/=]+\z}
      expect(encrypted).not_to include "\n"
    end
  end

  describe '.aes256_gcm_decrypt' do
    let(:encrypted) { described_class.aes256_gcm_encrypt('some-value') }

    it 'correctly decrypts encrypted string' do
      decrypted = described_class.aes256_gcm_decrypt(encrypted)

      expect(decrypted).to eq 'some-value'
    end

    it 'decrypts a value when it ends with a new line character' do
      decrypted = described_class.aes256_gcm_decrypt(encrypted + "\n")

      expect(decrypted).to eq 'some-value'
    end
  end
end
