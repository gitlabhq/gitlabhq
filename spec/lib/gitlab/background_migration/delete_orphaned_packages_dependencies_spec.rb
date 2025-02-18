# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedPackagesDependencies, schema: 20231220225325,
  feature_category: :package_registry do
  let!(:migration_attrs) do
    {
      start_id: 1,
      end_id: 1000,
      batch_table: :packages_dependencies,
      batch_column: :id,
      sub_batch_size: 500,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }

  let(:packages_dependencies) { table(:packages_dependencies) }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:namespace) do
    table(:namespaces).create!(name: 'project', path: 'project', type: 'Project', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project', path: 'project', project_namespace_id: namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:package) do
    table(:packages_packages).create!(name: 'test', version: '1.2.3', package_type: 2, project_id: project.id)
  end

  let!(:orphan_dependency_1) { packages_dependencies.create!(name: 'dependency 1', version_pattern: '~0.0.1') }
  let!(:orphan_dependency_2) { packages_dependencies.create!(name: 'dependency 2', version_pattern: '~0.0.2') }
  let!(:orphan_dependency_3) { packages_dependencies.create!(name: 'dependency 3', version_pattern: '~0.0.3') }
  let!(:linked_dependency) do
    packages_dependencies.create!(name: 'dependency 4', version_pattern: '~0.0.4').tap do |dependency|
      table(:packages_dependency_links).create!(package_id: package.id, dependency_id: dependency.id,
        dependency_type: 'dependencies')
    end
  end

  subject(:perform_migration) { migration.perform }

  it 'executes 3 queries' do
    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    expect(queries.count).to eq(3)
  end

  it 'deletes only orphaned dependencies' do
    expect { perform_migration }.to change { packages_dependencies.count }.by(-3)
    expect(packages_dependencies.all).to eq([linked_dependency])
  end
end
