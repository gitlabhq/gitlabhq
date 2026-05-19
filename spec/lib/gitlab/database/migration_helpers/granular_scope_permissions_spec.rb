# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::GranularScopePermissions, feature_category: :permissions do
  include MigrationsHelpers

  let(:granular_scopes) { table(:granular_scopes) }
  let(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'Organization', path: 'organization') }

  let(:old_permission) { 'write_work_item' }
  let(:new_permissions) { %w[create_work_item update_work_item] }

  let(:migration) { ActiveRecord::Migration.new.extend(described_class) }

  subject(:perform_rename) do
    migration.send(:rename_granular_scope_permission, old_permission, new_permissions,
      batch_scope: granular_scopes.select(:id).to_sql)
  end

  context 'when a new permission already exists in the array' do
    let!(:scope_with_overlap) do
      granular_scopes.create!(
        organization_id: organization.id,
        permissions: %w[write_work_item create_work_item],
        access: 0
      )
    end

    it 'deduplicates the result' do
      perform_rename

      expect(parse_permissions(scope_with_overlap)).to match_array(%w[create_work_item update_work_item])
    end
  end

  context 'when permissions contain duplicate old permission values' do
    let!(:scope_with_duplicates) do
      granular_scopes.create!(
        organization_id: organization.id,
        permissions: %w[write_work_item read_wiki write_work_item],
        access: 0
      )
    end

    it 'removes all occurrences of the old permission' do
      perform_rename

      expect(parse_permissions(scope_with_duplicates)).to match_array(%w[create_work_item update_work_item read_wiki])
    end
  end

  context 'when permissions is an empty array' do
    let!(:scope_with_empty) do
      granular_scopes.create!(
        organization_id: organization.id,
        permissions: [],
        access: 0
      )
    end

    it 'leaves the row untouched' do
      perform_rename

      expect(parse_permissions(scope_with_empty)).to be_empty
    end
  end

  context 'when new_permissions is an empty array' do
    let(:new_permissions) { [] }

    let!(:scope) do
      granular_scopes.create!(
        organization_id: organization.id,
        permissions: %w[write_work_item read_wiki],
        access: 0
      )
    end

    it 'removes the old permission without adding new ones' do
      perform_rename

      expect(parse_permissions(scope)).to match_array(%w[read_wiki])
    end
  end

  context 'when new_permissions is a single string' do
    let(:new_permissions) { 'create_work_item' }

    let!(:scope) do
      granular_scopes.create!(
        organization_id: organization.id,
        permissions: %w[write_work_item read_wiki],
        access: 0
      )
    end

    it 'handles a single new permission' do
      perform_rename

      expect(parse_permissions(scope)).to match_array(%w[create_work_item read_wiki])
    end
  end

  describe '#perform' do
    let(:migration_class) do
      Class.new(Gitlab::BackgroundMigration::BatchedMigrationJob) do
        const_set(:RENAMES, {
          'write_work_item' => %w[create_work_item update_work_item],
          'manage_deploy_key' => 'admin_deploy_key'
        }.freeze)

        include Gitlab::Database::MigrationHelpers::GranularScopePermissions
      end
    end

    let!(:scope_with_both) do
      granular_scopes.create!(
        organization_id: organization.id,
        permissions: %w[write_work_item manage_deploy_key read_wiki],
        access: 0
      )
    end

    let!(:scope_with_one) do
      granular_scopes.create!(
        organization_id: organization.id,
        permissions: %w[manage_deploy_key read_code],
        access: 0
      )
    end

    let!(:scope_with_none) do
      granular_scopes.create!(
        organization_id: organization.id,
        permissions: %w[read_wiki read_code],
        access: 0
      )
    end

    let(:migration) do
      migration_class.new(
        start_cursor: [scope_with_both.id],
        end_cursor: [scope_with_none.id],
        batch_table: :granular_scopes,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        job_arguments: [],
        connection: ApplicationRecord.connection
      )
    end

    it 'renames all matching permissions in a single pass' do
      migration.perform

      expect(parse_permissions(scope_with_both)).to match_array(
        %w[create_work_item update_work_item admin_deploy_key read_wiki]
      )
    end

    it 'handles rows with only some of the old permissions' do
      migration.perform

      expect(parse_permissions(scope_with_one)).to match_array(%w[admin_deploy_key read_code])
    end

    it 'leaves rows without any old permission untouched' do
      migration.perform

      expect(parse_permissions(scope_with_none)).to match_array(%w[read_wiki read_code])
    end

    context 'when a row is outside the cursor range' do
      let!(:scope_outside_range) do
        granular_scopes.create!(
          organization_id: organization.id,
          permissions: %w[write_work_item manage_deploy_key],
          access: 0
        )
      end

      it 'does not process the row' do
        migration.perform

        expect(parse_permissions(scope_outside_range)).to match_array(%w[write_work_item manage_deploy_key])
      end
    end

    context 'when a new permission already exists alongside the old one' do
      let!(:scope_with_overlap) do
        granular_scopes.create!(
          organization_id: organization.id,
          permissions: %w[write_work_item create_work_item manage_deploy_key admin_deploy_key],
          access: 0
        )
      end

      let(:migration) do
        migration_class.new(
          start_cursor: [scope_with_overlap.id],
          end_cursor: [scope_with_overlap.id],
          batch_table: :granular_scopes,
          batch_column: :id,
          sub_batch_size: 100,
          pause_ms: 0,
          job_arguments: [],
          connection: ApplicationRecord.connection
        )
      end

      it 'deduplicates the result' do
        migration.perform

        expect(parse_permissions(scope_with_overlap)).to match_array(
          %w[create_work_item update_work_item admin_deploy_key]
        )
      end
    end
  end

  private

  def parse_permissions(record)
    record.reload.permissions
  end
end
