# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::EncryptMissedCiRunnerTokens,
  migration: :gitlab_ci, feature_category: :fleet_visibility do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runners) { table(:ci_runners, primary_key: :id) }

    let(:args) do
      min, max = runners.pick('MIN(id)', 'MAX(id)')
      {
        start_id: min,
        end_id: max,
        batch_table: 'ci_runners',
        batch_column: 'id',
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      }
    end

    let!(:runner_with_plain_token) { runners.create!(runner_type: 1, token: 'plain_token') }
    let!(:runner_without_token) { runners.create!(runner_type: 1, token: nil, token_encrypted: nil) }
    let!(:runner_with_encrypted_token) do
      runners.create!(runner_type: 1, token: nil,
        token_encrypted: Gitlab::CryptoHelper.aes256_gcm_encrypt(SecureRandom.hex(32)))
    end

    let!(:runner_with_plain_and_encrypted_token) do
      runners.create!(runner_type: 1, token: 'plain_token2',
        token_encrypted: Gitlab::CryptoHelper.aes256_gcm_encrypt('encrypted_token2'))
    end

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'encrypts plain tokens', :aggregate_failures do
      expect { perform_migration }
        .to change { runner_with_plain_token.reload.token_encrypted }
          .from(nil).to(Authn::TokenField::EncryptionHelper.encrypt_token('plain_token'))
        .and change { runner_with_plain_token.reload.token }.to(nil)
        .and not_change { runner_with_encrypted_token.reload.token }
        .and not_change { runner_with_encrypted_token.reload.token_encrypted }
        .and not_change { runner_with_plain_and_encrypted_token.reload.token }
        .and not_change { runner_with_plain_and_encrypted_token.reload.token_encrypted }
        .and not_change { runner_without_token.reload.token }
        .and not_change { runner_without_token.reload.token_encrypted }
    end
  end
end
