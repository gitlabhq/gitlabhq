# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteStalePackagesNpmMetadataCaches, feature_category: :package_registry do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace) do
    table(:namespaces).create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project', path: 'project', project_namespace_id: namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:cache_1) do
    table(:packages_npm_metadata_caches).create!(package_name: 'test-1', size: 1, file: 'metadata.json',
      object_storage_key: '/packages/metadata_caches/npm/aaa', project_id: project.id)
  end

  let!(:package_2) do
    table(:packages_npm_metadata_caches).create!(package_name: 'test-2', size: 1, file: 'metadata.json',
      object_storage_key: '/packages/metadata_caches/npm/bbb', project_id: nil)
  end

  let!(:starting_id) { table(:packages_npm_metadata_caches).minimum(:id) }
  let!(:end_id) { table(:packages_npm_metadata_caches).maximum(:id) }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :packages_npm_metadata_caches,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'deletes entries with missing `project_id`' do
    expect { migration.perform }
      .to not_change { table(:packages_npm_metadata_caches).where.not(project_id: nil).count }
      .and change { table(:packages_npm_metadata_caches).where(project_id: nil).count }
      .from(1)
      .to(0)
  end
end
