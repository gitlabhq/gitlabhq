# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateStatusForDeprecatedNpmPackages, feature_category: :package_registry do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:namespace) do
    table(:namespaces).create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project', path: 'project', project_namespace_id: namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:package_1) do
    table(:packages_packages).create!(name: 'test', version: '1.0.0', package_type: 2, project_id: project.id)
      .tap do |package|
      table(:packages_npm_metadata).create!(package_json: { deprecated: 'not supported' }, package_id: package.id)
    end
  end

  let!(:package_2) do
    table(:packages_packages).create!(name: 'test', version: '2.0.0', package_type: 2, project_id: project.id)
      .tap do |package|
      table(:packages_npm_metadata).create!(package_json: { deprecated: 'not supported' }, package_id: package.id)
    end
  end

  let!(:package_3) do
    table(:packages_packages).create!(name: 'test', version: '3.0.0', package_type: 2, project_id: project.id)
      .tap do |package|
      table(:packages_npm_metadata).create!(package_json: {}, package_id: package.id)
    end
  end

  let!(:starting_id) { table(:packages_npm_metadata).minimum(:package_id) }
  let!(:end_id) { table(:packages_npm_metadata).maximum(:package_id) }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :packages_npm_metadata,
      batch_column: :package_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'updates the status for deprecated npm packages' do
    expect { migration.perform }
      .to change { package_1.reload.status }.from(0).to(5)
      .and change { package_2.reload.status }.from(0).to(5)
      .and not_change { package_3.reload.status }
  end
end
