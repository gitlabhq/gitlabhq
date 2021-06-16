# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe GenerateCiJwtSigningKey do
  let(:application_settings) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'application_settings'

      attr_encrypted :ci_jwt_signing_key, {
        mode: :per_attribute_iv,
        key: Gitlab::Utils.ensure_utf8_size(Rails.application.secrets.db_key_base, bytes: 32.bytes),
        algorithm: 'aes-256-gcm',
        encode: true
      }
    end
  end

  it 'generates JWT signing key' do
    application_settings.create!

    reversible_migration do |migration|
      migration.before -> {
        settings = application_settings.first

        expect(settings.ci_jwt_signing_key).to be_nil
        expect(settings.encrypted_ci_jwt_signing_key).to be_nil
        expect(settings.encrypted_ci_jwt_signing_key_iv).to be_nil
      }

      migration.after -> {
        settings = application_settings.first

        expect(settings.encrypted_ci_jwt_signing_key).to be_present
        expect(settings.encrypted_ci_jwt_signing_key_iv).to be_present
        expect { OpenSSL::PKey::RSA.new(settings.ci_jwt_signing_key) }.not_to raise_error
      }
    end
  end
end
