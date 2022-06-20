# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::SetLegacyOpenSourceLicenseAvailableForNonPublicProjects,
               :migration,
               schema: 20220520040416 do
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:project_settings_table) { table(:project_settings) }

  subject(:perform_migration) do
    described_class.new(start_id: 1,
                        end_id: 30,
                        batch_table: :projects,
                        batch_column: :id,
                        sub_batch_size: 2,
                        pause_ms: 0,
                        connection: ActiveRecord::Base.connection)
                   .perform
  end

  let(:queries) { ActiveRecord::QueryRecorder.new { perform_migration } }

  before do
    namespaces_table.create!(id: 1, name: 'namespace', path: 'namespace-path-1')
    namespaces_table.create!(id: 2, name: 'namespace', path: 'namespace-path-2', type: 'Project')
    namespaces_table.create!(id: 3, name: 'namespace', path: 'namespace-path-3', type: 'Project')
    namespaces_table.create!(id: 4, name: 'namespace', path: 'namespace-path-4', type: 'Project')

    projects_table
      .create!(id: 11, name: 'proj-1', path: 'path-1', namespace_id: 1, project_namespace_id: 2, visibility_level: 0)
    projects_table
      .create!(id: 12, name: 'proj-2', path: 'path-2', namespace_id: 1, project_namespace_id: 3, visibility_level: 10)
    projects_table
      .create!(id: 13, name: 'proj-3', path: 'path-3', namespace_id: 1, project_namespace_id: 4, visibility_level: 20)

    project_settings_table.create!(project_id: 11, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: 12, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: 13, legacy_open_source_license_available: true)
  end

  it 'sets `legacy_open_source_license_available` attribute to false for non-public projects', :aggregate_failures do
    expect(queries.count).to eq(3)

    expect(migrated_attribute(11)).to be_falsey
    expect(migrated_attribute(12)).to be_falsey
    expect(migrated_attribute(13)).to be_truthy
  end

  def migrated_attribute(project_id)
    project_settings_table.find(project_id).legacy_open_source_license_available
  end
end
