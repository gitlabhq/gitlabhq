# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MarkVirtualRegistriesPackagesMavenCacheEntriesPendingDestruction, feature_category: :virtual_registry do
  let(:connection) { ApplicationRecord.connection }

  let(:organization) { table(:organizations).create!(name: 'test-org', path: 'test-org') }
  let(:virtual_registries_packages_maven_cache_entries) { table(:virtual_registries_packages_maven_cache_entries) }

  let(:namespace) do
    table(:namespaces).create!(
      name: 'test-namespace',
      path: 'test-namespace',
      type: 'Group',
      organization_id: organization.id
    )
  end

  let(:upstream) do
    table(:virtual_registries_packages_maven_upstreams).create!(
      group_id: namespace.id,
      url: 'https://repo.maven.apache.org/maven2'
    )
  end

  let!(:cache_entry_1) do
    virtual_registries_packages_maven_cache_entries.create!(
      group_id: namespace.id,
      upstream_id: upstream.id,
      relative_path: 'com/example/artifact/1.0.0/artifact-1.0.0.jar',
      object_storage_key: 'key1',
      size: 1024,
      file_sha1: Gitlab::Database::ShaAttribute.serialize('5937ac0a7beb003549fc5fd26fc247adbce4a52e'),
      file: 'artifact-1.0.0.jar',
      status: 0 # default status
    )
  end

  let!(:cache_entry_2) do
    virtual_registries_packages_maven_cache_entries.create!(
      group_id: namespace.id,
      upstream_id: upstream.id,
      relative_path: 'com/example/artifact/1.0.1/artifact-1.0.1.jar',
      object_storage_key: 'key2',
      size: 2048,
      file_sha1: Gitlab::Database::ShaAttribute.serialize('5937ac0a7beb003549fc5fd26fc247adbce4a52e'),
      file: 'artifact-1.0.1.jar',
      status: 1 # processing status
    )
  end

  let!(:cache_entry_3) do
    virtual_registries_packages_maven_cache_entries.create!(
      group_id: namespace.id,
      upstream_id: upstream.id,
      relative_path: 'com/example/artifact/1.0.2/artifact-1.0.2.jar',
      object_storage_key: 'key3',
      size: 3072,
      file_sha1: Gitlab::Database::ShaAttribute.serialize('5937ac0a7beb003549fc5fd26fc247adbce4a44e'),
      file: 'artifact-1.0.2.jar',
      status: 2 # already pending_destruction
    )
  end

  let(:start_cursor) { [upstream.id, '', 0] }
  let(:end_cursor) { [upstream.id, cache_entry_3.relative_path, cache_entry_3.status] }

  subject(:perform_migration) do
    described_class.new(
      start_cursor: start_cursor,
      end_cursor: end_cursor,
      batch_table: :virtual_registries_packages_maven_cache_entries,
      batch_column: :upstream_id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: connection
    ).perform
  end

  it 'marks all cache entries as pending_destruction' do
    expect { perform_migration }
      .to change { virtual_registries_packages_maven_cache_entries.where(status: 2).count }.by(2)
  end
end
