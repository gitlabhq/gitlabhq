# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CryptoHelper, feature_category: :system_access do
  let(:encryption_key) { ::Gitlab::Encryption::KeyProvider[:db_key_base_32].encryption_key.secret }
  let(:default_iv) { Gitlab::Utils.ensure_utf8_size(encryption_key, bytes: 12.bytes) }

  describe '.sha256' do
    it 'generates SHA256 digest Base46 encoded' do
      digest = described_class.sha256('some-value')

      expect(digest).to match %r{\A[A-Za-z0-9+/=]+\z}
      expect(digest).to eq digest.strip
    end
  end

  describe 'with several db_key_base keys' do
    include DbKeyBaseHelpers

    let(:old_key) { Settings.db_key_base_keys.last }
    let(:new_key) { SecureRandom.hex(64) }

    def digest_with(key, value)
      Digest::SHA256.base64digest("#{value}#{key[0..31]}")
    end

    before do
      stub_db_key_base_keys(old_key, new_key)
    end

    describe '.sha256' do
      it 'salts with the current key' do
        expect(described_class.sha256('value')).to eq(digest_with(new_key, 'value'))
      end
    end

    describe '.sha256_candidates' do
      it 'returns a digest per key, current key first' do
        expect(described_class.sha256_candidates('value'))
          .to eq([digest_with(new_key, 'value'), digest_with(old_key, 'value')])
      end

      it 'returns a single digest for identical keys' do
        stub_db_key_base_keys(new_key, new_key)

        expect(described_class.sha256_candidates('value')).to eq([digest_with(new_key, 'value')])
      end
    end

    describe '.aes256_gcm_encrypt_candidates' do
      it 'returns a ciphertext per key, current key first, that each key decrypts' do
        candidates = described_class.aes256_gcm_encrypt_candidates('value')

        expect(candidates.first).to eq(described_class.aes256_gcm_encrypt('value'))
        expect(candidates.size).to eq(2)
        expect(candidates.map { |candidate| described_class.aes256_gcm_decrypt(candidate) }).to all(eq('value'))
      end
    end
  end

  describe '.aes256_gcm_encrypt' do
    let(:base_encrypt_options) { { algorithm: 'aes-256-gcm', key: encryption_key, value: 'some-value' } }

    it 'is Base64 encoded string without new line character' do
      encrypted = described_class.aes256_gcm_encrypt('some-value')

      expect(encrypted).to match %r{\A[A-Za-z0-9+/=]+\z}
      expect(encrypted).not_to include "\n"
    end

    it 'encrypts using static iv' do
      expect(Encryptor).to receive(:encrypt).with(base_encrypt_options.merge(iv: default_iv)).and_return('hashed_value')

      described_class.aes256_gcm_encrypt('some-value')
    end

    context 'with provided iv' do
      let(:iv) { create_nonce }

      it 'encrypts using provided iv' do
        expect(Encryptor).to receive(:encrypt).with(base_encrypt_options.merge(iv: iv)).and_return('hashed_value')

        described_class.aes256_gcm_encrypt('some-value', nonce: iv)
      end
    end
  end

  describe '.aes256_gcm_decrypt' do
    context 'when token was encrypted using static nonce' do
      let(:encrypted) { described_class.aes256_gcm_encrypt('some-value', nonce: default_iv) }

      it 'correctly decrypts encrypted string' do
        decrypted = described_class.aes256_gcm_decrypt(encrypted)

        expect(decrypted).to eq 'some-value'
      end

      it 'decrypts a value when it ends with a new line character' do
        decrypted = described_class.aes256_gcm_decrypt(encrypted + "\n")

        expect(decrypted).to eq 'some-value'
      end
    end

    context 'when token was encrypted using random nonce' do
      let(:value) { 'random-value' }
      let(:iv) { create_nonce }
      let(:encrypted) { described_class.aes256_gcm_encrypt(value, nonce: iv) }

      it 'correctly decrypts encrypted string' do
        decrypted = described_class.aes256_gcm_decrypt(encrypted, nonce: iv)

        expect(decrypted).to eq value
      end
    end
  end

  def create_nonce
    ::Digest::SHA256.hexdigest('my-value').bytes.take(Authn::TokenField::EncryptionHelper::NONCE_SIZE).pack('c*')
  end
end
