# frozen_string_literal: true

require 'spec_helper'
require_migration! 'migrate_disable_merge_trains_value'

RSpec.describe MigrateDisableMergeTrainsValue, schema: 20230929155123, feature_category: :continuous_integration do
  let!(:feature_gates) { table(:feature_gates) }
  let!(:projects) { table(:projects) }
  let!(:project_ci_cd_settings) { table(:project_ci_cd_settings) }
  let!(:namespace1) { table(:namespaces).create!(name: 'name1', path: 'path1') }
  let!(:namespace2) { table(:namespaces).create!(name: 'name2', path: 'path2') }

  let!(:project_with_flag_on) do
    projects
      .create!(
        name: "project",
        path: "project",
        namespace_id: namespace1.id,
        project_namespace_id: namespace1.id
      )
  end

  let!(:project_with_flag_off) do
    projects
      .create!(
        name: "project2",
        path: "project2",
        namespace_id: namespace2.id,
        project_namespace_id: namespace2.id
      )
  end

  let!(:settings_flag_on) do
    project_ci_cd_settings.create!(
      merge_trains_enabled: true,
      project_id: project_with_flag_on.id
    )
  end

  let!(:settings_flag_off) do
    project_ci_cd_settings.create!(
      merge_trains_enabled: true,
      project_id: project_with_flag_off.id
    )
  end

  let!(:migration) { described_class.new }

  before do
    # Enable the feature flag
    feature_gates.create!(
      feature_key: 'disable_merge_trains',
      key: 'actors',
      value: "Project:#{project_with_flag_on.id}"
    )

    migration.up
  end

  describe '#up' do
    it 'migrates the flag value into the setting value' do
      expect(
        settings_flag_on.reload.merge_trains_enabled
      ).to eq(false)
      expect(
        settings_flag_off.reload.merge_trains_enabled
      ).to eq(true)
    end
  end

  describe '#down' do
    it 'reverts the migration' do
      migration.down

      expect(
        settings_flag_on.reload.merge_trains_enabled
      ).to eq(true)
      expect(
        settings_flag_off.reload.merge_trains_enabled
      ).to eq(true)
    end
  end
end
