# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EncryptFeatureFlagsClientsTokens do
  let(:migration) { described_class.new }
  let(:feature_flags_clients) { table(:operations_feature_flags_clients) }
  let(:projects) { table(:projects) }
  let(:plaintext) { "secret-token" }
  let(:ciphertext) { Gitlab::CryptoHelper.aes256_gcm_encrypt(plaintext, nonce: Gitlab::CryptoHelper::AES256_GCM_IV_STATIC) }

  describe '#up' do
    it 'keeps plaintext token the same and populates token_encrypted if not present' do
      project = projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
      feature_flags_client = feature_flags_clients.create!(project_id: project.id, token: plaintext)

      migration.up

      expect(feature_flags_client.reload.token).to eq(plaintext)
      expect(feature_flags_client.reload.token_encrypted).to eq(ciphertext)
    end
  end

  describe '#down' do
    it 'decrypts encrypted token and saves it' do
      project = projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
      feature_flags_client = feature_flags_clients.create!(project_id: project.id, token_encrypted: ciphertext)

      migration.down

      expect(feature_flags_client.reload.token).to eq(plaintext)
      expect(feature_flags_client.reload.token_encrypted).to eq(ciphertext)
    end
  end
end
