# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::SetLegacyOpenSourceLicenseAvailableForNonPublicProjects,
  :migration,
  schema: 20231220225325 do
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:project_settings_table) { table(:project_settings) }

  subject(:perform_migration) do
    described_class.new(
      start_id: projects_table.minimum(:id),
      end_id: projects_table.maximum(:id),
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'sets `legacy_open_source_license_available` attribute to false for non-public projects', :aggregate_failures do
    private_project = create_legacy_license_project('private-project', visibility_level: 0)
    internal_project = create_legacy_license_project('internal-project', visibility_level: 10)
    public_project = create_legacy_license_project('public-project', visibility_level: 20)

    queries = ActiveRecord::QueryRecorder.new { perform_migration }

    expect(queries.count).to eq(5)

    expect(migrated_attribute(private_project)).to be_falsey
    expect(migrated_attribute(internal_project)).to be_falsey
    expect(migrated_attribute(public_project)).to be_truthy
  end

  def create_legacy_license_project(path, visibility_level:)
    organization = organizations_table.create!(name: "organization-#{path}", path: "organization-#{path}")

    namespace = namespaces_table.create!(
      name: "namespace-#{path}",
      path: "namespace-#{path}",
      organization_id: organization.id
    )

    project_namespace = namespaces_table.create!(
      name: "project-namespace-#{path}",
      path: path,
      type: 'Project',
      organization_id: organization.id
    )

    project = projects_table.create!(
      organization_id: organization.id,
      name: path,
      path: path,
      namespace_id: namespace.id,
      project_namespace_id: project_namespace.id,
      visibility_level: visibility_level
    )

    project_settings_table.create!(project_id: project.id, legacy_open_source_license_available: true)

    project
  end

  def migrated_attribute(project)
    project_settings_table.find(project.id).legacy_open_source_license_available
  end
end
