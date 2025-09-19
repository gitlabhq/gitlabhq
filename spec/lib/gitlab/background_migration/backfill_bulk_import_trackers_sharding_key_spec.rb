# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBulkImportTrackersShardingKey, feature_category: :importers do
  let(:connection) { ApplicationRecord.connection }

  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:user) do
    table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 10,
      organization_id: organization.id)
  end

  let!(:namespace) { table(:namespaces).create!(name: 'name', path: 'path', organization_id: organization.id) }
  let!(:project) do
    table(:projects).create!(name: 'project', path: 'project', organization_id: organization.id,
      project_namespace_id: namespace.id, namespace_id: namespace.id)
  end

  let!(:bulk_import) do
    table(:bulk_imports).create!(user_id: user.id, source_type: 0, status: 0, organization_id: organization.id)
  end

  let(:bulk_import_entities) { table(:bulk_import_entities) }
  let(:bulk_import_trackers) { table(:bulk_import_trackers) }
  let(:migration_args) do
    {
      start_id: bulk_import_trackers.minimum(:id),
      end_id: bulk_import_trackers.maximum(:id),
      batch_table: :bulk_import_trackers,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'backfill correct sharding key column' do
    entity1 = bulk_import_entities.create!(
      bulk_import_id: bulk_import.id,
      source_type: 'organization_entity',
      source_full_path: 'source-path-1',
      destination_name: 'imported-entity',
      destination_namespace: 'destination-path-1',
      status: 0,
      migrate_projects: true,
      migrate_memberships: true,
      organization_id: organization.id,
      namespace_id: nil,
      project_id: nil
    )
    entity2 = bulk_import_entities.create!(
      bulk_import_id: bulk_import.id,
      source_type: 'namespace_entity',
      source_full_path: 'source-path-2',
      destination_name: 'imported-entity',
      destination_namespace: 'destination-path-2',
      status: 0,
      migrate_projects: true,
      migrate_memberships: true,
      organization_id: nil,
      namespace_id: nil,
      project_id: project.id
    )

    drop_constraint_and_trigger

    tracker1 = bulk_import_trackers.create!(
      bulk_import_entity_id: entity1.id,
      relation: 'pipeline_name_1',
      organization_id: nil,
      namespace_id: nil,
      project_id: nil
    )
    tracker1.reload
    expect(tracker1.organization_id).to be_nil
    expect(tracker1.namespace_id).to be_nil
    expect(tracker1.project_id).to be_nil

    tracker2 = bulk_import_trackers.create!(
      bulk_import_entity_id: entity2.id,
      relation: 'pipeline_name_1',
      organization_id: organization.id,
      namespace_id: namespace.id,
      project_id: project.id
    )
    tracker2.reload
    expect(tracker2.organization_id).to eq(organization.id)
    expect(tracker2.namespace_id).to eq(namespace.id)
    expect(tracker2.project_id).to eq(project.id)

    recreate_constraint_and_trigger
    described_class.new(**migration_args).perform

    tracker1.reload
    expect(tracker1.organization_id).to eq(organization.id)
    expect(tracker1.namespace_id).to be_nil
    expect(tracker1.project_id).to be_nil

    tracker2.reload
    expect(tracker2.organization_id).to be_nil
    expect(tracker2.namespace_id).to be_nil
    expect(tracker2.project_id).to eq(project.id)
  end

  private

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS trigger_bulk_import_trackers_sharding_key ON bulk_import_trackers;

        ALTER TABLE bulk_import_trackers DROP CONSTRAINT IF EXISTS check_5f034e7cad;
      SQL
    )
  end

  def recreate_constraint_and_trigger
    connection.execute(
      <<~SQL
        ALTER TABLE bulk_import_trackers
          ADD CONSTRAINT check_5f034e7cad CHECK ((num_nonnulls(namespace_id, organization_id, project_id) = 1)) NOT VALID;

        CREATE TRIGGER trigger_bulk_import_trackers_sharding_key BEFORE INSERT OR UPDATE
          ON bulk_import_trackers FOR EACH ROW EXECUTE FUNCTION bulk_import_trackers_sharding_key();
      SQL
    )
  end
end
