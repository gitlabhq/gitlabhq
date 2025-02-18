# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNugetNormalizedVersion, schema: 20231220225325,
  feature_category: :package_registry do
  let(:packages_nuget_metadata) { table(:packages_nuget_metadata) }
  let(:versions) do
    {
      '1' => '1.0.0',
      '1.0' => '1.0.0',
      '1.0.0' => '1.0.0',
      '1.00' => '1.0.0',
      '1.00.01' => '1.0.1',
      '1.01.1' => '1.1.1',
      '1.0.0.0' => '1.0.0',
      '1.0.01.0' => '1.0.1',
      '1.0.7+r3456' => '1.0.7',
      '1.0.0-Alpha' => '1.0.0-alpha',
      '1.00.05-alpha.0' => '1.0.5-alpha.0'
    }
  end

  let!(:migration_attrs) do
    {
      start_id: packages_nuget_metadata.minimum(:package_id),
      end_id: packages_nuget_metadata.maximum(:package_id),
      batch_table: :packages_nuget_metadata,
      batch_column: :package_id,
      sub_batch_size: 1000,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let(:migration) { described_class.new(**migration_attrs) }
  let(:packages) { table(:packages_packages) }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) do
    table(:namespaces).create!(name: 'project', path: 'project', type: 'Project', organization_id: organization.id)
  end

  let(:project) do
    table(:projects).create!(name: 'project', path: 'project', project_namespace_id: namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:package_ids) { [] }

  subject(:perform_migration) { migration.perform }

  before do
    versions.each_key do |version|
      packages.create!(name: 'test', version: version, package_type: 4, project_id: project.id).tap do |package|
        package_ids << package.id
        packages_nuget_metadata.create!(package_id: package.id)
      end
    end
  end

  it 'executes 5 queries and updates the normalized_version column' do
    queries = ActiveRecord::QueryRecorder.new do
      perform_migration
    end

    # each_batch lower bound query
    # each_batch upper bound query
    # SELECT packages_nuget_metadata.package_id FROM packages_nuget_metadata....
    # SELECT packages_packages.id, packages_packages.version FROM packages_packages....
    # UPDATE packages_nuget_metadata SET normalized_version =....
    expect(queries.count).to eq(5)

    expect(
      packages_nuget_metadata.where(package_id: package_ids).pluck(:normalized_version)
    ).to match_array(versions.values)
  end
end
