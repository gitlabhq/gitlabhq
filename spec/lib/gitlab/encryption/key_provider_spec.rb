# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Encryption::KeyProvider, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  describe 'supported key providers' do
    def wrap_secrets(secrets)
      secrets.map do |secret|
        ActiveRecord::Encryption::Key.new(secret)
      end
    end

    def derive_secrets(secrets)
      secrets.map do |secret|
        ActiveRecord::Encryption::Key.new(ActiveRecord::Encryption.key_generator.derive_key_from(secret))
      end
    end

    # rubocop:disable Layout/LineLength -- We cannot break lines when using RSpec::Parameterized::TableSyntax
    where(:key_type, :expected_key_provider_class, :expected_keys) do
      :db_key_base | Gitlab::Encryption::NonDerivedKeyProvider | wrap_secrets(Settings.db_key_base_keys)
      :db_key_base_truncated | Gitlab::Encryption::NonDerivedKeyProvider | wrap_secrets(Settings.db_key_base_keys_32_bytes)
      :db_key_base_32 | Gitlab::Encryption::NonDerivedKeyProvider | wrap_secrets(Settings.db_key_base_keys_truncated)
      :active_record_encryption_primary_key | ActiveRecord::Encryption::DerivedSecretKeyProvider | derive_secrets(ActiveRecord::Encryption.config.primary_key)
      :active_record_encryption_deterministic_key | ActiveRecord::Encryption::DerivedSecretKeyProvider | derive_secrets(ActiveRecord::Encryption.config.deterministic_key)
    end
    # rubocop:enable Layout/LineLength

    with_them do
      describe '.[]' do
        it 'returns the expected key provider wrapper' do
          expect(described_class[key_type])
            .to be_a(Gitlab::Encryption::KeyProviderWrapper)
        end

        it 'returns the expected key provider class from the wrapper' do
          expect(described_class[key_type].key_provider)
            .to be_a(expected_key_provider_class)
        end
      end

      describe 'instance methods' do
        subject(:service) { described_class[key_type] }

        describe '#key_provider' do
          it 'instantiates the expected key provider' do
            expect(service.key_provider)
              .to be_a(expected_key_provider_class)
          end
        end

        describe '#encryption_key' do
          it 'returns the last key' do
            expect(service.encryption_key.secret)
              .to eq(expected_keys.last.secret)
          end

          it 'includes a public tag referencing the key' do
            expect(service.encryption_key.public_tags.encrypted_data_key_id)
              .to eq(service.encryption_key.id)
          end
        end

        describe '#decryption_keys' do
          it 'returns ActiveRecord::Encryption::Key keys' do
            provider_keys = service.decryption_keys

            expect(provider_keys)
              .to all(be_a(ActiveRecord::Encryption::Key))
          end

          it 'returns all keys by default' do
            expect(service.decryption_keys.map(&:secret))
              .to eq(expected_keys.map(&:secret))
          end
        end
      end
    end
  end
end
