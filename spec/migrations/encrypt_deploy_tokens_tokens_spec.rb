# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db', 'post_migrate', '20190711201818_encrypt_deploy_tokens_tokens.rb')

describe EncryptDeployTokensTokens, :migration do
  let(:migration) { described_class.new }
  let(:deployment_tokens) { table(:deploy_tokens) }
  let(:plaintext) { "secret-token" }
  let(:expires_at) { DateTime.now + 1.year }
  let(:ciphertext) { Gitlab::CryptoHelper.aes256_gcm_encrypt(plaintext) }

  describe '#up' do
    it 'keeps plaintext token the same and populates token_encrypted if not present' do
      deploy_token = deployment_tokens.create!(
        name: 'test_token',
        read_repository: true,
        expires_at: expires_at,
        username: 'gitlab-token-1',
        token: plaintext
      )

      migration.up

      expect(deploy_token.reload.token).to eq(plaintext)
      expect(deploy_token.reload.token_encrypted).to eq(ciphertext)
    end
  end

  describe '#down' do
    it 'decrypts encrypted token and saves it' do
      deploy_token = deployment_tokens.create!(
        name: 'test_token',
        read_repository: true,
        expires_at: expires_at,
        username: 'gitlab-token-1',
        token_encrypted: ciphertext
      )

      migration.down

      expect(deploy_token.reload.token).to eq(plaintext)
      expect(deploy_token.reload.token_encrypted).to eq(ciphertext)
    end
  end
end
