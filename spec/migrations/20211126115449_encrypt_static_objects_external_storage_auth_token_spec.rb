# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EncryptStaticObjectsExternalStorageAuthToken, :migration, feature_category: :source_code_management do
  let(:application_settings) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'application_settings'
    end
  end

  context 'when static_objects_external_storage_auth_token is not set' do
    it 'does nothing' do
      application_settings.create!

      reversible_migration do |migration|
        migration.before -> {
          settings = application_settings.first

          expect(settings.static_objects_external_storage_auth_token).to be_nil
          expect(settings.static_objects_external_storage_auth_token_encrypted).to be_nil
        }

        migration.after -> {
          settings = application_settings.first

          expect(settings.static_objects_external_storage_auth_token).to be_nil
          expect(settings.static_objects_external_storage_auth_token_encrypted).to be_nil
        }
      end
    end
  end

  context 'when static_objects_external_storage_auth_token is set' do
    it 'encrypts static_objects_external_storage_auth_token' do
      settings = application_settings.create!
      settings.update_column(:static_objects_external_storage_auth_token, 'Test')

      reversible_migration do |migration|
        migration.before -> {
          settings = application_settings.first

          expect(settings.static_objects_external_storage_auth_token).to eq('Test')
          expect(settings.static_objects_external_storage_auth_token_encrypted).to be_nil
        }
        migration.after -> {
          settings = application_settings.first

          expect(settings.static_objects_external_storage_auth_token).to eq('Test')
          expect(settings.static_objects_external_storage_auth_token_encrypted).to be_present
        }
      end
    end
  end

  context 'when static_objects_external_storage_auth_token is empty string' do
    it 'does not break' do
      settings = application_settings.create!
      settings.update_column(:static_objects_external_storage_auth_token, '')

      reversible_migration do |migration|
        migration.before -> {
          settings = application_settings.first

          expect(settings.static_objects_external_storage_auth_token).to eq('')
          expect(settings.static_objects_external_storage_auth_token_encrypted).to be_nil
        }
        migration.after -> {
          settings = application_settings.first

          expect(settings.static_objects_external_storage_auth_token).to eq('')
          expect(settings.static_objects_external_storage_auth_token_encrypted).to be_nil
        }
      end
    end
  end
end
