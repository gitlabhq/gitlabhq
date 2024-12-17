# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCatalogResourceVersionsReleasedAt,
  feature_category: :pipeline_composition do
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: 'name', path: 'path', organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:resource) { table(:catalog_resources).create!(project_id: project.id) }

  let(:releases_table) { table(:releases) }
  let(:versions_table) { table(:catalog_resource_versions) }

  let(:release1) { releases_table.create!(tag: 'v1', released_at: '2024-01-01T00:00:00Z') }
  let(:release2) { releases_table.create!(tag: 'v2', released_at: '2024-02-02T00:00:00Z') }
  let(:release3) { releases_table.create!(tag: 'v3', released_at: '2025-03-03T00:00:00Z') }

  let(:version1) do
    versions_table.create!(release_id: release1.id, catalog_resource_id: resource.id, project_id: project.id)
  end

  let(:version2) do
    versions_table.create!(release_id: release2.id, catalog_resource_id: resource.id, project_id: project.id)
  end

  let(:version3) do
    versions_table.create!(release_id: release3.id, catalog_resource_id: resource.id, project_id: project.id)
  end

  subject(:perform_migration) do
    described_class.new(
      start_id: versions_table.minimum(:id),
      end_id: versions_table.maximum(:id),
      batch_table: :catalog_resource_versions,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'updates catalog_resource_versions.released_at with the corresponding value from releases.released_at' do
    expect { perform_migration }
      .to change { version1.reload.released_at }.to(release1.released_at)
      .and change { version2.reload.released_at }.to(release2.released_at)
      .and change { version3.reload.released_at }.to(release3.released_at)

    perform_migration
  end
end
