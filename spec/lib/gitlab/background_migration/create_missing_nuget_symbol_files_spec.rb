# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CreateMissingNugetSymbolFiles, feature_category: :package_registry do
  let!(:organization) { table(:organizations).create!(name: 'default org', path: 'dflt') }

  let!(:namespace) do
    table(:namespaces).create!(name: 'group-1', path: 'group-1', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    table(:projects).create!(name: 'project 2', path: 'project-1', project_namespace_id: namespace.id,
      namespace_id: namespace.id, organization_id: organization.id)
  end

  let!(:package_1) do
    table(:packages_packages).create!(name: 'test 1', version: '1.2.3', package_type: 4, project_id: project.id,
      created_at: Date.parse('2024-11-08'))
  end

  let!(:package_2) do
    table(:packages_packages).create!(name: 'test 2', version: '1.2.3', package_type: 4, project_id: project.id,
      created_at: Date.parse('2024-11-09'))
  end

  let!(:package_3) do
    table(:packages_packages).create!(name: 'test 3', version: '1.2.3', package_type: 4, project_id: project.id,
      created_at: Date.parse('2024-11-11'))
  end

  let!(:package_4) do
    table(:packages_packages).create!(name: 'test 4', version: '1.2.4', package_type: 4, project_id: project.id,
      created_at: Date.parse('2024-11-12'))
  end

  let!(:file) { fixture_file_upload('spec/fixtures/packages/nuget/package.nupkg') }

  let!(:package_file_1) do
    table(:packages_package_files).create!(file: file, file_name: 'package.snupkg',
      file_sha1: '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57', size: 300.kilobytes, package_id: package_1.id,
      created_at: Date.parse('2024-11-08'))
  end

  let!(:package_file_2) do
    table(:packages_package_files).create!(file: file, file_name: 'package.snupkg',
      file_sha1: '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57', size: 300.kilobytes, package_id: package_2.id,
      created_at: Date.parse('2024-11-09'))
  end

  let!(:package_file_3) do
    table(:packages_package_files).create!(file: file, file_name: 'package.snupkg',
      file_sha1: '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57', size: 300.kilobytes, package_id: package_3.id,
      created_at: Date.parse('2024-11-11'))
  end

  let!(:package_file_4) do
    table(:packages_package_files).create!(file: file, file_name: 'package.snupkg',
      file_sha1: '5fe852b2a6abd96c22c11fa1ff2fb19d9ce58b57', size: 300.kilobytes, package_id: package_4.id,
      created_at: Date.parse('2024-11-12'))
  end

  let!(:symbol) do
    table(:packages_nuget_symbols).create!(
      file: fixture_file_upload('spec/fixtures/packages/nuget/symbol/package.pdb'),
      file_path: 'lib/net7.0/package.pdb',
      file_sha256: 'dd1aaf26c557685cc37f93f53a2b6befb2c2e679f5ace6ec7a26d12086f358be',
      size: 300.kilobytes,
      signature: 'b91a152048fc4b3883bf3cf73fbc03f1FFFFFFFF',
      package_id: package_3.id,
      project_id: project.id,
      object_storage_key: 'key'
    )
  end

  let!(:starting_id) { table(:packages_packages).minimum(:id) }
  let!(:end_id) { table(:packages_packages).maximum(:id) }

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

  it 'enqueues the background worker for packages without symbols', :aggregate_failures do
    expect(::Packages::Nuget::CreateSymbolsWorker).to receive(:perform_in)
      .with(0.seconds, package_file_1.id).ordered
    expect(::Packages::Nuget::CreateSymbolsWorker).to receive(:perform_in)
      .with(1.second, package_file_2.id).ordered
    expect(::Packages::Nuget::CreateSymbolsWorker).not_to receive(:perform_in)
      .with(instance_of(ActiveSupport::Duration), package_file_3.id)
    expect(::Packages::Nuget::CreateSymbolsWorker).not_to receive(:perform_in)
      .with(instance_of(ActiveSupport::Duration), package_file_4.id)

    migration.perform
  end
end
