# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::EncryptCiTriggerToken, feature_category: :continuous_integration do
  let(:ci_triggers) do
    table(:ci_triggers, database: :ci) do |ci_trigger|
      ci_trigger.send :attr_encrypted, :encrypted_token_tmp,
        attribute: :encrypted_token,
        mode: :per_attribute_iv,
        key: ::Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm',
        encode: false
    end
  end

  let(:without_encryption) { ci_triggers.create!(token: "token", owner_id: 1) }
  let(:without_encryption_2) { ci_triggers.create!(token: "token 2", owner_id: 1) }
  let(:with_encryption) { ci_triggers.create!(token: 'token 3', owner_id: 1, encrypted_token_tmp: 'token 3') }

  let(:start_id) { ci_triggers.minimum(:id) }
  let(:end_id) { ci_triggers.maximum(:id) }

  let(:migration_attrs) do
    {
      start_id: start_id,
      end_id: end_id,
      batch_table: :ci_triggers,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  it 'ensures all unencrypted tokens are encrypted' do
    expect(without_encryption.encrypted_token).to eq(nil)
    expect(without_encryption_2.encrypted_token).to eq(nil)
    expect(with_encryption.encrypted_token).not_to be(nil)

    described_class.new(**migration_attrs).perform

    updated_triggers = [without_encryption, without_encryption_2]
    updated_triggers.each do |stale_trigger|
      db_trigger = Ci::Trigger.find(stale_trigger.id)
      expect(db_trigger.encrypted_token).not_to be(nil)
      expect(db_trigger.encrypted_token_iv).not_to be(nil)
      expect(db_trigger.token).to eq(db_trigger.encrypted_token_tmp)
    end

    already_encrypted_token = Ci::Trigger.find(with_encryption.id)
    expect(already_encrypted_token.encrypted_token).to eq(with_encryption.encrypted_token)
    expect(already_encrypted_token.encrypted_token_iv).to eq(with_encryption.encrypted_token_iv)
    expect(already_encrypted_token.token).to eq(already_encrypted_token.encrypted_token_tmp)
    expect(with_encryption.token).to eq(with_encryption.encrypted_token_tmp)
  end
end
