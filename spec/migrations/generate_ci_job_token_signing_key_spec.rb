# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe GenerateCiJobTokenSigningKey, feature_category: :continuous_integration do
  let(:application_settings) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'application_settings'

      attr_encrypted :ci_job_token_signing_key, {
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm',
        encode: false,
        encode_iv: false
      }
    end
  end

  it 'generates a signing key' do
    application_settings.create!

    reversible_migration do |migration|
      migration.before -> {
        settings = application_settings.first

        expect(settings.ci_job_token_signing_key).to be_nil
        expect(settings.encrypted_ci_job_token_signing_key).to be_nil
        expect(settings.encrypted_ci_job_token_signing_key_iv).to be_nil
      }

      migration.after -> {
        settings = application_settings.first

        expect(settings.encrypted_ci_job_token_signing_key).to be_present
        expect(settings.encrypted_ci_job_token_signing_key_iv).to be_present
        expect { OpenSSL::PKey::RSA.new(settings.ci_job_token_signing_key) }.not_to raise_error
      }
    end
  end
end
