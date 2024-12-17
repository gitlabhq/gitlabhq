# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesDependenciesProjectId, feature_category: :package_registry do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:namespace_1) do
    table(:namespaces).create!(name: 'group-1', path: 'group-1', type: 'Group', organization_id: organization.id)
  end

  let!(:namespace_2) do
    table(:namespaces).create!(name: 'group-2', path: 'group-2', type: 'Group', organization_id: organization.id)
  end

  let!(:project_1) do
    table(:projects).create!(name: 'project 1', path: 'project-1', project_namespace_id: namespace_1.id,
      namespace_id: namespace_1.id, organization_id: organization.id)
  end

  let!(:project_2) do
    table(:projects).create!(name: 'project 2', path: 'project-2', project_namespace_id: namespace_2.id,
      namespace_id: namespace_2.id, organization_id: organization.id)
  end

  let!(:package_1) do
    table(:packages_packages).create!(name: 'test 1', version: '1.2.3', package_type: 2, project_id: project_1.id)
  end

  let!(:package_2) do
    table(:packages_packages).create!(name: 'test 2', version: '1.2.3', package_type: 2, project_id: project_2.id)
  end

  let!(:dependencies) do
    3.times do |i|
      table(:packages_dependencies).create!(name: 'foobar', version_pattern: "~#{i}.0.0").tap do |dependency|
        table(:packages_dependency_links).create!(package_id: package_1.id, dependency_id: dependency.id,
          dependency_type: 'dependencies')
        table(:packages_dependency_links).create!(package_id: package_2.id, dependency_id: dependency.id,
          dependency_type: 'dependencies')
      end
    end
  end

  let!(:starting_id) { table(:packages_dependency_links).minimum(:id) }
  let!(:end_id) { table(:packages_dependency_links).maximum(:id) }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :packages_dependency_links,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'backfills the missing `project_id` for packages dependencies' do
    expect { migration.perform }
      .to change { table(:packages_dependencies).where.not(project_id: nil).count }
      .from(0)
      .to(6)
  end
end
