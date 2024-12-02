# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DisableLegacyOpenSourceLicenseForInactivePublicProjects, :migration do
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

  let(:queries) { ActiveRecord::QueryRecorder.new { perform_migration } }

  let(:organization) { organizations_table.create!(name: 'organization', path: 'organization') }

  let(:namespace_1) { create_namespace('namespace-1') }
  let(:project_namespace_2) { create_namespace('namespace-2', 'Project') }
  let(:project_namespace_3) { create_namespace('namespace-3', 'Project') }
  let(:project_namespace_4) { create_namespace('namespace-4', 'Project') }
  let(:project_namespace_5) { create_namespace('namespace-5', 'Project') }

  let(:project_1) do
    projects_table.create!(
      name: 'proj-1', path: 'path-1', namespace_id: namespace_1.id, organization_id: organization.id,
      project_namespace_id: project_namespace_2.id, visibility_level: 0
    )
  end

  let(:project_2) do
    projects_table.create!(
      name: 'proj-2', path: 'path-2', namespace_id: namespace_1.id, organization_id: organization.id,
      project_namespace_id: project_namespace_3.id, visibility_level: 10
    )
  end

  let(:project_3) do
    projects_table.create!(
      name: 'proj-3', path: 'path-3', namespace_id: namespace_1.id, organization_id: organization.id,
      project_namespace_id: project_namespace_4.id, visibility_level: 20, last_activity_at: '2021-01-01'
    )
  end

  let(:project_4) do
    projects_table.create!(
      name: 'proj-4', path: 'path-4', namespace_id: namespace_1.id, organization_id: organization.id,
      project_namespace_id: project_namespace_5.id, visibility_level: 20, last_activity_at: '2022-01-01'
    )
  end

  before do
    project_settings_table.create!(project_id: project_1.id, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: project_2.id, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: project_3.id, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: project_4.id, legacy_open_source_license_available: true)
  end

  it 'sets `legacy_open_source_license_available` attribute to false for inactive, public projects',
    :aggregate_failures do
    expect(queries.count).to eq(5)

    expect(migrated_attribute(project_1.id)).to be_truthy
    expect(migrated_attribute(project_2.id)).to be_truthy
    expect(migrated_attribute(project_3.id)).to be_falsey
    expect(migrated_attribute(project_4.id)).to be_truthy
  end

  def migrated_attribute(project_id)
    project_settings_table.find(project_id).legacy_open_source_license_available
  end

  def create_namespace(name, type = 'User')
    namespaces_table.create!(name: name, path: name, type: type, organization_id: organization.id)
  end
end
