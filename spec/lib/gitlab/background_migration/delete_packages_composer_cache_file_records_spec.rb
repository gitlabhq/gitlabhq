# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeletePackagesComposerCacheFileRecords, feature_category: :package_registry do
  let(:packages_composer_cache_files) do
    klass = table(:packages_composer_cache_files)
    klass.include(FileStoreMounter)
    klass.mount_file_store_uploader(::Packages::Composer::CacheUploader)
    klass
  end

  let!(:namespace) { table(:namespaces).create!(name: 'group', path: 'group', type: 'Group') }
  let!(:file) { fixture_file_upload('spec/fixtures/packages/composer/package.json') }

  let!(:cache_file_1) do
    packages_composer_cache_files.create!(
      file_sha256: '1' * 64,
      namespace_id: namespace.id,
      file: file
    )
  end

  let!(:cache_file_2) do
    packages_composer_cache_files.create!(
      file_sha256: '2' * 64,
      namespace_id: namespace.id,
      file: file
    )
  end

  let!(:file_1) { cache_file_1.file }
  let!(:file_2) { cache_file_2.file }
  let!(:start_id) { packages_composer_cache_files.minimum(:id) }
  let!(:end_id) { packages_composer_cache_files.maximum(:id) }

  let!(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :packages_composer_cache_files,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  subject(:perform_migration) { migration.perform }

  it 'deletes packages composer cache files' do
    expect { perform_migration }.to change { packages_composer_cache_files.count }.by(-2)
  end

  it 'deletes the linked files', :aggregate_failures do
    expect(file_1).to be_exists
    expect(file_2).to be_exists

    perform_migration

    expect(file_1).not_to be_exists
    expect(file_2).not_to be_exists
  end
end
