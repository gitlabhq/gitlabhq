# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DisableLegacyOpenSourceLicenceForRecentPublicProjects, :migration do
  let(:namespaces_table) { table(:namespaces) }
  let(:namespace_1) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-1') }
  let(:project_namespace_2) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-2', type: 'Project') }
  let(:project_namespace_3) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-3', type: 'Project') }
  let(:project_namespace_4) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-4', type: 'Project') }
  let(:project_namespace_5) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-5', type: 'Project') }
  let(:project_namespace_6) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-6', type: 'Project') }
  let(:project_namespace_7) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-7', type: 'Project') }
  let(:project_namespace_8) { namespaces_table.create!(name: 'namespace', path: 'namespace-path-8', type: 'Project') }

  let(:project_1) do
    projects_table
      .create!(
        name: 'proj-1', path: 'path-1', namespace_id: namespace_1.id,
        project_namespace_id: project_namespace_2.id, visibility_level: 0
      )
  end

  let(:project_2) do
    projects_table
      .create!(
        name: 'proj-2', path: 'path-2', namespace_id: namespace_1.id,
        project_namespace_id: project_namespace_3.id, visibility_level: 10, created_at: '2022-02-22'
      )
  end

  let(:project_3) do
    projects_table
      .create!(
        name: 'proj-3', path: 'path-3', namespace_id: namespace_1.id,
        project_namespace_id: project_namespace_4.id, visibility_level: 20, created_at: '2022-02-17 09:00:01'
      )
  end

  let(:project_4) do
    projects_table
      .create!(
        name: 'proj-4', path: 'path-4', namespace_id: namespace_1.id,
        project_namespace_id: project_namespace_5.id, visibility_level: 20, created_at: '2022-02-01'
      )
  end

  let(:project_5) do
    projects_table
      .create!(
        name: 'proj-5', path: 'path-5', namespace_id: namespace_1.id,
        project_namespace_id: project_namespace_6.id, visibility_level: 20, created_at: '2022-01-04'
      )
  end

  let(:project_6) do
    projects_table
      .create!(
        name: 'proj-6', path: 'path-6', namespace_id: namespace_1.id,
        project_namespace_id: project_namespace_7.id, visibility_level: 20, created_at: '2022-02-17 08:59:59'
      )
  end

  let(:project_7) do
    projects_table
      .create!(
        name: 'proj-7', path: 'path-7', namespace_id: namespace_1.id,
        project_namespace_id: project_namespace_8.id, visibility_level: 20, created_at: '2022-02-17 09:00:00'
      )
  end

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

  before do
    project_settings_table.create!(project_id: project_1.id, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: project_2.id, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: project_3.id, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: project_4.id, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: project_5.id, legacy_open_source_license_available: false)
    project_settings_table.create!(project_id: project_6.id, legacy_open_source_license_available: true)
    project_settings_table.create!(project_id: project_7.id, legacy_open_source_license_available: true)
  end

  it 'sets `legacy_open_source_license_available` attribute to false for public projects created after threshold time',
    :aggregate_failures do
    record = ActiveRecord::QueryRecorder.new do
      expect { perform_migration }
        .to not_change { migrated_attribute(project_1.id) }.from(true)
        .and not_change { migrated_attribute(project_2.id) }.from(true)
        .and change { migrated_attribute(project_3.id) }.from(true).to(false)
        .and not_change { migrated_attribute(project_4.id) }.from(true)
        .and not_change { migrated_attribute(project_5.id) }.from(false)
        .and not_change { migrated_attribute(project_6.id) }.from(true)
        .and change { migrated_attribute(project_7.id) }.from(true).to(false)
    end
    expect(record.count).to eq(19)
  end

  def migrated_attribute(project_id)
    project_settings_table.find(project_id).legacy_open_source_license_available
  end
end
