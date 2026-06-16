# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Assignable::CleanupDeprecatedTask, feature_category: :permissions do
  subject(:run) { described_class.new.run }

  let(:finalize_version) { '20260423235043' }
  let(:finalize_milestone) { '19.0' }
  let(:current_milestone) { '19.1' }

  let(:permission_source_file) do
    Rails.root.join('config/authz/permission_groups/assignable_permissions/foo/bar/read.yml').to_s
  end

  let(:deprecated_permission) do
    Authz::PermissionGroups::Assignable.new(
      {
        name: 'read_bar',
        deprecated: true,
        description: 'An old permission',
        permissions: [:read_bar],
        boundaries: ['project'],
        available_for: ['granular_access_token']
      },
      permission_source_file
    )
  end

  let(:bbm_doc_path) { '/fake/db/docs/batched_background_migrations/rename_bar.yml' }
  let(:post_migrate_path) { "/fake/db/post_migrate/#{finalize_version}_finalize_rename_bar.rb" }

  let(:bbm_doc_yaml) do
    { 'migration_job_name' => 'FakeRenameJob', 'finalized_by' => finalize_version }.to_yaml
  end

  let(:post_migrate_content) do
    <<~RUBY
      class FinalizeRenameBar < Gitlab::Database::Migration[2.3]
        milestone '#{finalize_milestone}'
      end
    RUBY
  end

  before do
    stub_const('Gitlab::BackgroundMigration::FakeRenameJob', Class.new.tap do |klass|
      klass.const_set(:RENAMES, { 'read_bar' => 'read_baz' }.freeze)
    end)

    allow(::Gitlab).to receive(:current_milestone).and_return(current_milestone)
    allow(Authz::PermissionGroups::Assignable).to receive(:definitions).and_return([deprecated_permission])

    allow(Dir).to receive(:glob).with(described_class::BBM_DOCS_GLOB).and_return([bbm_doc_path])
    allow(File).to receive(:read).with(bbm_doc_path).and_return(bbm_doc_yaml)

    allow(Dir).to receive(:glob)
      .with(described_class::POST_MIGRATE_DIR.join("#{finalize_version}_*.rb"))
      .and_return([post_migrate_path])
    allow(File).to receive(:read).with(post_migrate_path).and_return(post_migrate_content)

    allow(File).to receive(:delete)
  end

  it 'deletes the deprecated permission file' do
    expect(File).to receive(:delete).with(permission_source_file)

    run
  end

  context 'when the finalize milestone equals the current milestone' do
    let(:current_milestone) { finalize_milestone }

    it 'does not delete anything' do
      expect(File).not_to receive(:delete)

      run
    end
  end

  context 'when the finalize milestone is after the current milestone' do
    let(:current_milestone) { '18.11' }

    it 'does not delete anything' do
      expect(File).not_to receive(:delete)

      run
    end
  end

  context 'when finalized_by is blank' do
    let(:bbm_doc_yaml) { { 'migration_job_name' => 'FakeRenameJob', 'finalized_by' => nil }.to_yaml }

    it 'does not delete anything' do
      expect(File).not_to receive(:delete)

      run
    end
  end

  context 'when the post-migrate file does not exist' do
    before do
      allow(Dir).to receive(:glob)
        .with(described_class::POST_MIGRATE_DIR.join("#{finalize_version}_*.rb"))
        .and_return([])
    end

    it 'does not delete anything' do
      expect(File).not_to receive(:delete)

      run
    end
  end

  context 'when the BBM worker class cannot be found' do
    let(:bbm_doc_yaml) { { 'migration_job_name' => 'NonExistentJob', 'finalized_by' => finalize_version }.to_yaml }

    it 'does not delete anything' do
      expect(File).not_to receive(:delete)

      run
    end
  end

  context 'when the BBM worker class has no RENAMES constant' do
    before do
      stub_const('Gitlab::BackgroundMigration::FakeRenameJob', Class.new)
    end

    it 'does not delete anything' do
      expect(File).not_to receive(:delete)

      run
    end
  end

  context 'when the permission is not deprecated' do
    let(:deprecated_permission) do
      Authz::PermissionGroups::Assignable.new(
        {
          name: 'read_bar',
          deprecated: false,
          description: 'A current permission',
          permissions: [:read_bar],
          boundaries: ['project'],
          available_for: ['granular_access_token']
        },
        permission_source_file
      )
    end

    it 'does not delete anything' do
      expect(File).not_to receive(:delete)

      run
    end
  end

  context 'when the permission name is not in the BBM RENAMES' do
    let(:deprecated_permission) do
      Authz::PermissionGroups::Assignable.new(
        {
          name: 'unrelated_permission',
          deprecated: true,
          description: 'Deprecated but unrelated',
          permissions: [:unrelated_permission],
          boundaries: ['project'],
          available_for: ['granular_access_token']
        },
        permission_source_file
      )
    end

    it 'does not delete anything' do
      expect(File).not_to receive(:delete)

      run
    end
  end

  context 'when there are multiple files to delete' do
    let(:second_source_file) do
      Rails.root.join('config/authz/permission_groups/assignable_permissions/foo/bar/create.yml').to_s
    end

    let(:second_permission) do
      Authz::PermissionGroups::Assignable.new(
        {
          name: 'create_bar',
          deprecated: true,
          description: 'Another old permission',
          permissions: [:create_bar],
          boundaries: ['project'],
          available_for: ['granular_access_token']
        },
        second_source_file
      )
    end

    before do
      stub_const('Gitlab::BackgroundMigration::FakeRenameJob', Class.new.tap do |klass|
        klass.const_set(:RENAMES, { 'read_bar' => 'read_baz', 'create_bar' => 'create_baz' }.freeze)
      end)

      allow(Authz::PermissionGroups::Assignable).to receive(:definitions)
        .and_return([deprecated_permission, second_permission])
    end

    it 'deletes all matching files' do
      expect(File).to receive(:delete).with(permission_source_file)
      expect(File).to receive(:delete).with(second_source_file)

      run
    end
  end

  context 'when there are no deprecated permissions at all' do
    before do
      allow(Authz::PermissionGroups::Assignable).to receive(:definitions).and_return([])
    end

    it 'prints a message and does not delete anything' do
      expect(File).not_to receive(:delete)
      expect { run }.to output(/No deprecated permission files are ready for deletion/).to_stdout
    end
  end
end
