# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupTerminatedBulkImportConfigs, feature_category: :importers do
  describe '#perform' do
    let(:organizations_table) { table(:organizations, database: :main, primary_key: :id) }
    let(:bulk_imports_table) { table(:bulk_imports, database: :main, primary_key: :id) }
    let(:bulk_import_configurations_table) { table(:bulk_import_configurations, database: :main, primary_key: :id) }
    let(:users_table) { table(:users, database: :main, primary_key: :id) }

    let!(:organization) { organizations_table.create!(name: 'default', path: 'default', visibility_level: 20) }
    let!(:user) do
      users_table.create!(
        email: 'name@default.com',
        encrypted_password: '$2a$13$uxbY5Hw',
        projects_limit: 100000,
        admin: false, username: 'name',
        can_create_group: true,
        can_create_team: true,
        color_scheme_id: 1,
        otp_required_for_login: false,
        auditor: false,
        require_two_factor_authentication_from_group: false,
        two_factor_grace_period: 48,
        private_profile: false,
        onboarding_in_progress: false,
        color_mode_id: 1,
        composite_identity_enforced: false,
        organization_id: organization.id
      )
    end

    let!(:bulk_import_with_config_finished) do
      bulk_imports_table.create!(user_id: user.id, source_type: 0, status: 2, source_enterprise: true,
        organization_id: organization.id)
    end

    let!(:configuration_finished) do
      bulk_import_configurations_table.create!(bulk_import_id: bulk_import_with_config_finished.id)
    end

    let!(:bulk_import_with_config_timeout) do
      bulk_imports_table.create!(user_id: user.id, source_type: 0, status: 3, source_enterprise: true,
        organization_id: organization.id)
    end

    let!(:configuration_timeout) do
      bulk_import_configurations_table.create!(bulk_import_id: bulk_import_with_config_timeout.id)
    end

    let!(:bulk_import_with_config_failed) do
      bulk_imports_table.create!(user_id: user.id, source_type: 0, status: -1, source_enterprise: true,
        organization_id: organization.id)
    end

    let!(:configuration_failed) do
      bulk_import_configurations_table.create!(bulk_import_id: bulk_import_with_config_failed.id)
    end

    let!(:bulk_import_with_config_canceled) do
      bulk_imports_table.create!(user_id: user.id, source_type: 0, status: -2, source_enterprise: true,
        organization_id: organization.id)
    end

    let!(:configuration_canceled) do
      bulk_import_configurations_table.create!(bulk_import_id: bulk_import_with_config_canceled.id)
    end

    let!(:bulk_import_without_config_canceled) do
      bulk_imports_table.create!(user_id: user.id, source_type: 0, status: -2, source_enterprise: true,
        organization_id: organization.id)
    end

    subject(:migration) do
      described_class.new(
        batch_table: :bulk_imports,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      )
    end

    it 'destroys old bulk import configurations' do
      migration.perform

      migration_model = Gitlab::BackgroundMigration::CleanupTerminatedBulkImportConfigs::BulkImport

      expect(migration_model.find(bulk_import_with_config_canceled.id).configuration).to be_nil
      expect(migration_model.find(bulk_import_with_config_failed.id).configuration).to be_nil
      expect(migration_model.find(bulk_import_with_config_finished.id).configuration).to be_nil
      expect(migration_model.find(bulk_import_with_config_timeout.id).configuration).to be_nil
    end

    it 'ignores bulk imports without configurations' do
      expect { migration.perform }.to not_change { bulk_import_without_config_canceled.reload }
    end
  end
end
