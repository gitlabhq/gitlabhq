# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Doctor::EncryptionKeys, feature_category: :shared do
  let(:logger) { instance_double(Logger).as_null_object }

  subject(:doctor_encryption_secrets) { described_class.new(logger).run! }

  it 'outputs current encryption secrets IDs, and truncated actual secrets' do
    expect(logger).to receive(:info)
      .with(/- active_record_encryption_primary_key: ID => `\w{4}`; truncated secret => `\w{3}...\w{3}`/)
    expect(logger).to receive(:info)
      .with(/- active_record_encryption_deterministic_key: ID => `\w{4}`; truncated secret => `\w{3}...\w{3}`/)

    doctor_encryption_secrets
  end

  context 'when no encrypted attributes exist' do
    it 'outputs "NONE"' do
      expect(logger).to receive(:info).with("Encryption keys usage for DependencyProxy::GroupSetting: NONE")

      doctor_encryption_secrets
    end
  end

  context 'when encrypted attributes exist' do
    let(:current_key_provider) { ActiveRecord::Encryption.key_provider }
    let(:unknown_key_provider) { ActiveRecord::Encryption::DerivedSecretKeyProvider.new(SecureRandom.base64(32)) }

    before do
      # Create a record with the current encryption key
      create(:dependency_proxy_group_setting)

      # Create a record with a different encryption key
      ActiveRecord::Encryption.with_encryption_context(key_provider: unknown_key_provider) do
        create(:dependency_proxy_group_setting)
      end
    end

    it 'detects decryptable secrets' do
      expect(logger).to receive(:info).with("Encryption keys usage for DependencyProxy::GroupSetting:")
      expect(logger).to receive(:info).with("- `#{current_key_provider.encryption_key.id}` => 2")
      expect(logger).to receive(:info).with("- `#{unknown_key_provider.encryption_key.id}` (UNKNOWN KEY!) => 2")

      doctor_encryption_secrets
    end
  end
end
