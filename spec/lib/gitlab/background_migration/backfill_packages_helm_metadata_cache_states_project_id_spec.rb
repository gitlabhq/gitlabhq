# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesHelmMetadataCacheStatesProjectId,
  feature_category: :geo_replication do
  it_behaves_like 'desired sharding key backfill job' do
    let(:batch_table) { :packages_helm_metadata_cache_states }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :id }
    let(:backfill_via_table) { :packages_helm_metadata_caches }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :packages_helm_metadata_cache_id }
  end

  describe '#perform' do
    let(:connection) { ApplicationRecord.connection }

    let(:organizations) { table(:organizations) }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:caches) { table(:packages_helm_metadata_caches) }
    let(:states) { table(:packages_helm_metadata_cache_states) }

    let(:constraint_name) { 'check_4afb385a32' }
    let(:trigger_name) { 'trigger_489fffe04425' }

    let(:organization) { organizations.create!(name: 'org', path: 'org') }
    let(:namespace) { namespaces.create!(name: 'ns', path: 'ns', organization_id: organization.id) }
    let(:project) do
      projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
    end

    let(:cache_with_existing_project) do
      caches.create!(
        project_id: project.id, size: 1, channel: 'stable', file: 'index.yaml', object_storage_key: 'key/existing'
      )
    end

    # project_id points at a project that no longer exists: the project was deleted
    # but the loose foreign key cleanup never marked the cache for destruction.
    let(:orphaned_cache) do
      caches.create!(
        project_id: non_existing_record_id, size: 1, channel: 'stable', file: 'index.yaml',
        object_storage_key: 'key/orphaned'
      )
    end

    let(:cache_already_backfilled) do
      caches.create!(
        project_id: project.id, size: 1, channel: 'devel', file: 'index.yaml', object_storage_key: 'key/backfilled'
      )
    end

    let!(:state_to_backfill) do
      without_constraint_and_trigger do
        states.create!(packages_helm_metadata_cache_id: cache_with_existing_project.id, project_id: nil)
      end
    end

    # Already has a valid project_id; the job must leave it untouched.
    let!(:already_backfilled_state) do
      states.create!(packages_helm_metadata_cache_id: cache_already_backfilled.id, project_id: project.id)
    end

    let!(:orphaned_state) do
      without_constraint_and_trigger do
        states.create!(packages_helm_metadata_cache_id: orphaned_cache.id, project_id: nil)
      end
    end

    let(:migration) do
      described_class.new(
        start_id: states.minimum(:id),
        end_id: states.maximum(:id),
        batch_table: :packages_helm_metadata_cache_states,
        batch_column: :id,
        sub_batch_size: 1,
        pause_ms: 0,
        connection: connection,
        job_arguments: [:project_id, :packages_helm_metadata_caches, :project_id, :packages_helm_metadata_cache_id]
      )
    end

    it 'backfills project_id from the parent cache when the project exists' do
      expect { migration.perform }
        .to change { state_to_backfill.reload.project_id }.from(nil).to(project.id)
    end

    it 'deletes the orphaned cache and cascades to its state' do
      expect { migration.perform }
        .to change { caches.where(id: orphaned_cache.id).exists? }.from(true).to(false)
        .and change { states.where(id: orphaned_state.id).exists? }.from(true).to(false)
    end

    it 'leaves already-backfilled states untouched' do
      migration.perform

      expect(states.where(id: already_backfilled_state.id).exists?).to be(true)
      expect(already_backfilled_state.reload.project_id).to eq(project.id)
    end

    def without_constraint_and_trigger
      connection.execute(<<~SQL)
        DROP TRIGGER IF EXISTS #{trigger_name} ON packages_helm_metadata_cache_states;
        ALTER TABLE packages_helm_metadata_cache_states DROP CONSTRAINT IF EXISTS #{constraint_name};
      SQL

      yield
    ensure
      connection.execute(<<~SQL)
        ALTER TABLE packages_helm_metadata_cache_states
          ADD CONSTRAINT #{constraint_name} CHECK ((project_id IS NOT NULL)) NOT VALID;
        CREATE TRIGGER #{trigger_name} BEFORE INSERT OR UPDATE ON packages_helm_metadata_cache_states
          FOR EACH ROW EXECUTE FUNCTION #{trigger_name}();
      SQL
    end
  end
end
