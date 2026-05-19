# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateSecretPushProtectionToJsonb, feature_category: :secret_detection do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    context 'when secret_push_protection_available is false' do
      before do
        application_settings.create!(secret_push_protection_available: false)
      end

      it 'migrates the value into JSONB and adds enforced as false' do
        migrate!

        settings = application_settings.first.reload
        jsonb = settings.read_attribute(:security_and_compliance_settings)
        expect(jsonb['secret_push_protection_available']).to be(false)
        expect(jsonb['secret_push_protection_enforced']).to be(false)
      end
    end

    context 'when secret_push_protection_available is true' do
      before do
        application_settings.create!(secret_push_protection_available: true)
      end

      it 'migrates the existing true value into JSONB' do
        migrate!

        settings = application_settings.first.reload
        jsonb = settings.read_attribute(:security_and_compliance_settings)
        expect(jsonb['secret_push_protection_available']).to be(true)
        expect(jsonb['secret_push_protection_enforced']).to be(false)
      end
    end

    context 'when security_and_compliance_settings already has other keys' do
      before do
        application_settings.create!(
          security_and_compliance_settings: { 'enforce_pipl_compliance' => true },
          secret_push_protection_available: false
        )
      end

      it 'preserves existing keys and adds the new ones' do
        migrate!

        settings = application_settings.first.reload
        jsonb = settings.read_attribute(:security_and_compliance_settings)
        expect(jsonb['enforce_pipl_compliance']).to be(true)
        expect(jsonb['secret_push_protection_available']).to be(false)
        expect(jsonb['secret_push_protection_enforced']).to be(false)
      end
    end
  end

  describe '#down' do
    context 'when security_and_compliance_settings has valid JSONB' do
      before do
        application_settings.create!(
          secret_push_protection_available: true,
          security_and_compliance_settings: {
            'enforce_pipl_compliance' => false,
            'secret_push_protection_available' => true,
            'secret_push_protection_enforced' => true
          }
        )
      end

      it 'removes both keys from JSONB and preserves other keys' do
        migrate!

        schema_migrate_down!

        settings = application_settings.first.reload
        jsonb = settings.read_attribute(:security_and_compliance_settings)
        expect(jsonb).not_to have_key('secret_push_protection_available')
        expect(jsonb).not_to have_key('secret_push_protection_enforced')
        expect(jsonb['enforce_pipl_compliance']).to be(false)
      end
    end
  end
end
