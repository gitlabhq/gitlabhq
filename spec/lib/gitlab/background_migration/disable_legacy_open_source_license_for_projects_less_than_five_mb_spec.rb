# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DisableLegacyOpenSourceLicenseForProjectsLessThanFiveMb,
  :migration,
  schema: 20230616082958,
  feature_category: :groups_and_projects do
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:project_settings_table) { table(:project_settings) }
  let(:project_statistics_table) { table(:project_statistics) }

  subject(:perform_migration) do
    described_class.new(
      start_id: project_settings_table.minimum(:project_id),
      end_id: project_settings_table.maximum(:project_id),
      batch_table: :project_settings,
      batch_column: :project_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'sets `legacy_open_source_license_available` to false only for projects less than 5 MiB', :aggregate_failures do
    project_setting_2_mb = create_legacy_license_project_setting(repo_size: 2)
    project_setting_4_mb = create_legacy_license_project_setting(repo_size: 4)
    project_setting_5_mb = create_legacy_license_project_setting(repo_size: 5)
    project_setting_6_mb = create_legacy_license_project_setting(repo_size: 6)

    record = ActiveRecord::QueryRecorder.new do
      expect { perform_migration }
        .to change { migrated_attribute(project_setting_2_mb) }.from(true).to(false)
        .and change { migrated_attribute(project_setting_4_mb) }.from(true).to(false)
        .and not_change { migrated_attribute(project_setting_5_mb) }.from(true)
        .and not_change { migrated_attribute(project_setting_6_mb) }.from(true)
    end

    expect(record.count).to eq(15)
  end

  private

  # @param repo_size: Repo size in MiB
  def create_legacy_license_project_setting(repo_size:)
    path = "path-for-repo-size-#{repo_size}"
    namespace = namespaces_table.create!(name: "namespace-#{path}", path: "namespace-#{path}")
    project_namespace = namespaces_table.create!(
      name: "-project-namespace-#{path}", path: "project-namespace-#{path}", type: 'Project'
    )
    project = projects_table.create!(
      name: path, path: path, namespace_id: namespace.id, project_namespace_id: project_namespace.id
    )

    size_in_bytes = 1.megabyte * repo_size
    project_statistics_table.create!(project_id: project.id, namespace_id: namespace.id, repository_size: size_in_bytes)
    project_settings_table.create!(project_id: project.id, legacy_open_source_license_available: true)
  end

  def migrated_attribute(project_setting)
    project_settings_table.find(project_setting.project_id).legacy_open_source_license_available
  end
end
