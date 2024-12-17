# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CreateMissingTerraformModuleMetadata, feature_category: :package_registry do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:namespace) do
    table(:namespaces).create!(name: 'group-1', path: 'group-1', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project 2', path: 'project-1', project_namespace_id: namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:package_1) do
    table(:packages_packages).create!(name: 'test 1', version: '1.2.3', package_type: 12, project_id: project.id,
      created_at: Date.parse('2024-10-18'))
  end

  let!(:package_2) do
    table(:packages_packages).create!(name: 'test 2', version: '1.2.3', package_type: 12, project_id: project.id,
      created_at: Date.parse('2024-10-18'))
  end

  let!(:package_3) do
    table(:packages_packages).create!(name: 'test 3', version: '1.2.3', package_type: 12, project_id: project.id,
      created_at: Date.parse('2024-10-19'))
  end

  let!(:file) { fixture_file_upload('spec/fixtures/packages/terraform_module/module-system-v1.0.0.zip') }

  let!(:package_file_1) do
    table(:packages_package_files).create!(file: file, file_name: 'module-system-v1.0.0.zip',
      file_sha1: 'abf850accb1947c0c0e3ef4b441b771bb5c9ae3c', size: 806.bytes, package_id: package_1.id)
  end

  let!(:package_file_2) do
    table(:packages_package_files).create!(file: file, file_name: 'module-system-v1.0.0.zip',
      file_sha1: 'abf850accb1947c0c0e3ef4b441b771bb5c9ae3c', size: 806.bytes, package_id: package_2.id)
  end

  let!(:package_file_3) do
    table(:packages_package_files).create!(file: file, file_name: 'module-system-v1.0.0.zip',
      file_sha1: 'abf850accb1947c0c0e3ef4b441b771bb5c9ae3c', size: 806.bytes, package_id: package_3.id)
  end

  let!(:starting_id) { table(:packages_dependency_links).minimum(:id) }
  let!(:end_id) { table(:packages_dependency_links).maximum(:id) }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :packages_packages,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'enqueues the background worker for packages without metadata', :aggregate_failures do
    expect(::Packages::TerraformModule::ProcessPackageFileWorker).to receive(:perform_in)
      .with(0.seconds, package_file_1.id).ordered
    expect(::Packages::TerraformModule::ProcessPackageFileWorker).to receive(:perform_in)
      .with(1.second, package_file_2.id).ordered
    expect(::Packages::TerraformModule::ProcessPackageFileWorker).not_to receive(:perform_in)
      .with(instance_of(ActiveSupport::Duration), package_file_3.id)

    migration.perform
  end
end
