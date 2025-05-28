# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MigrateAssetProxySecretKeyToNewEncryptionFramework, migration: :gitlab_main, feature_category: :cell do
  let(:table_name) { :application_settings }
  let(:batch_column) { :id }
  let(:sub_batch_size) { 1 }
  let(:migration) do
    described_class.new(
      start_id: 1, end_id: 10,
      batch_table: table_name, batch_column: batch_column,
      sub_batch_size: sub_batch_size,
      pause_ms: 2,
      connection: ApplicationRecord.connection
    )
  end

  let(:application_settings_with_attr_encrypted) do
    Class.new(ApplicationRecord) do
      include Gitlab::EncryptedAttribute

      self.table_name = 'application_settings'

      attr_encrypted :asset_proxy_secret_key,
        mode: :per_attribute_iv,
        key: :db_key_base_truncated,
        algorithm: 'aes-256-cbc',
        insecure_mode: true
    end
  end

  let(:application_settings_with_migrate_to_encrypts) do
    Class.new(ApplicationRecord) do
      include Gitlab::EncryptedAttribute

      self.table_name = 'application_settings'

      migrate_to_encrypts :asset_proxy_secret_key,
        mode: :per_attribute_iv,
        key: :db_key_base_truncated,
        algorithm: 'aes-256-cbc',
        insecure_mode: true
    end
  end

  let(:key) { 'super secret key' }

  before do
    application_settings_with_attr_encrypted.create!(id: 1, asset_proxy_secret_key: key)
  end

  describe '#up' do
    it "changes unknown deployment_types based on URL" do
      as_record = application_settings_with_migrate_to_encrypts.first
      expect(as_record.asset_proxy_secret_key).to eq(key)
      expect(as_record.tmp_asset_proxy_secret_key).to be_nil
      expect(as_record.attr_encrypted_asset_proxy_secret_key).to eq(key)
      expect(as_record.encrypted_asset_proxy_secret_key).to be_present
      expect(as_record.encrypted_asset_proxy_secret_key_iv).to be_present

      migrate!

      as_record.reload

      expect(as_record.asset_proxy_secret_key).to eq(key)
      expect(as_record.tmp_asset_proxy_secret_key).to eq(key)
      expect(as_record.attr_encrypted_asset_proxy_secret_key).to eq(key)
      expect(as_record.encrypted_asset_proxy_secret_key).to be_present
      expect(as_record.encrypted_asset_proxy_secret_key_iv).to be_present
    end
  end
end
