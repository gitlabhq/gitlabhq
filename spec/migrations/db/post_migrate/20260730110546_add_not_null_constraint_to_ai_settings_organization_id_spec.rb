# frozen_string_literal: true

require 'spec_helper'
require_migration!
require_migration!('backfill_organization_id_on_legacy_ai_settings')

RSpec.describe AddNotNullConstraintToAiSettingsOrganizationId, migration: :gitlab_main,
  feature_category: :ai_abstraction_layer do
  let(:migration) { described_class.new }
  let(:constraint_name) { 'check_6e16f4d23e' }
  let(:ai_settings) { table(:ai_settings) }
  let(:organizations) { table(:organizations) }

  describe '#up' do
    it 'adds the organization_id not null constraint after legacy settings are backfilled' do
      organizations.create!(id: BackfillOrganizationIdOnLegacyAiSettings::DEFAULT_ORG_ID,
        name: 'Default', path: 'default')
      legacy_setting = ai_settings.create!(organization_id: nil)

      BackfillOrganizationIdOnLegacyAiSettings.new.migrate(:up)

      expect(migration.check_constraint_exists?(:ai_settings, constraint_name)).to be(false)

      migration.migrate(:up)

      expect(migration.check_constraint_exists?(:ai_settings, constraint_name)).to be(true)
      expect(legacy_setting.reload.organization_id)
        .to eq(BackfillOrganizationIdOnLegacyAiSettings::DEFAULT_ORG_ID)
    end
  end

  describe '#down' do
    it 'removes the organization_id not null constraint' do
      migration.migrate(:up)

      migration.migrate(:down)

      expect(migration.check_constraint_exists?(:ai_settings, constraint_name)).to be(false)
    end
  end
end
