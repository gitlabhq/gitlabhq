# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBulkImportBatchTrackersShardingKey, feature_category: :importers do
  let(:connection) { ApplicationRecord.connection }

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let(:users) { table(:users) }
  let(:bulk_imports) { table(:bulk_imports) }
  let(:bulk_import_entities) { table(:bulk_import_entities) }
  let(:bulk_import_trackers) { table(:bulk_import_trackers) }
  let(:bulk_import_batch_trackers) { table(:bulk_import_batch_trackers) }

  let(:function_name) { 'bulk_import_batch_trackers_sharding_key' }
  let(:trigger_name) { "trigger_#{function_name}" }
  let(:constraint_name) { 'check_13004cd9a8' }

  let(:organization) { organizations.create!(name: 'name', path: 'path') }
  let(:namespace) { namespaces.create!(name: 'name', path: 'path', organization_id: organization.id) }
  let(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: organization.id)
  end

  let(:user) do
    users.create!(username: 'user', email: 'user@gitlab.com', projects_limit: 0, organization_id: organization.id)
  end

  let(:bulk_import) do
    bulk_imports.create!(
      user_id: user.id,
      source_type: 1,
      status: 1,
      organization_id: organization.id
    )
  end

  let(:bulk_import_entity) do
    bulk_import_entities.create!(
      bulk_import_id: bulk_import.id,
      source_type: 1,
      source_full_path: 'a',
      destination_name: 'a',
      destination_namespace: 'a',
      status: 1,
      organization_id: organization.id
    )
  end

  let(:tracker_belonging_to_organization) do
    bulk_import_trackers.create!(
      bulk_import_entity_id: bulk_import_entity.id,
      relation: 'a',
      organization_id: organization.id
    )
  end

  let(:batch_tracker_belonging_to_organization_without_organization_id) do
    drop_constraint_and_trigger
    record = bulk_import_batch_trackers.create!(
      tracker_id: tracker_belonging_to_organization.id,
      organization_id: nil,
      namespace_id: nil,
      project_id: nil
    )
    add_constraint_and_trigger
    record
  end

  let(:batch_tracker_belonging_to_organization_with_organization_id) do
    bulk_import_batch_trackers.create!(
      tracker_id: tracker_belonging_to_organization.id,
      batch_number: 1,
      organization_id: organization.id,
      namespace_id: nil,
      project_id: nil
    )
  end

  let(:batch_tracker_belonging_to_organization_with_all_sharding_columns) do
    drop_constraint_and_trigger
    record = bulk_import_batch_trackers.create!(
      tracker_id: tracker_belonging_to_organization.id,
      batch_number: 2,
      organization_id: organization.id,
      namespace_id: namespace.id,
      project_id: project.id
    )
    add_constraint_and_trigger
    record
  end

  subject(:migration) do
    described_class.new(
      start_id: bulk_import_batch_trackers.minimum(:id),
      end_id: bulk_import_batch_trackers.maximum(:id),
      batch_table: :bulk_import_batch_trackers,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe "#perform" do
    it 'sets sharding key for records that do not have it' do
      expect(batch_tracker_belonging_to_organization_without_organization_id.reload.organization_id).to be_nil
      expect(batch_tracker_belonging_to_organization_without_organization_id.reload.namespace_id).to be_nil
      expect(batch_tracker_belonging_to_organization_without_organization_id.reload.project_id).to be_nil

      expect(batch_tracker_belonging_to_organization_with_organization_id.reload.organization_id).to eq(organization.id)
      expect(batch_tracker_belonging_to_organization_with_organization_id.reload.namespace_id).to be_nil
      expect(batch_tracker_belonging_to_organization_with_organization_id.reload.project_id).to be_nil

      expect(batch_tracker_belonging_to_organization_with_all_sharding_columns.reload.organization_id)
        .to eq(organization.id)
      expect(batch_tracker_belonging_to_organization_with_all_sharding_columns.reload.namespace_id).to eq(namespace.id)
      expect(batch_tracker_belonging_to_organization_with_all_sharding_columns.reload.project_id).to eq(project.id)

      migration.perform

      expect(batch_tracker_belonging_to_organization_without_organization_id.reload.organization_id)
        .to eq(organization.id)
      expect(batch_tracker_belonging_to_organization_without_organization_id.reload.namespace_id).to be_nil
      expect(batch_tracker_belonging_to_organization_without_organization_id.reload.project_id).to be_nil

      expect(batch_tracker_belonging_to_organization_with_organization_id.reload.organization_id).to eq(organization.id)
      expect(batch_tracker_belonging_to_organization_with_organization_id.reload.namespace_id).to be_nil
      expect(batch_tracker_belonging_to_organization_with_organization_id.reload.project_id).to be_nil

      expect(batch_tracker_belonging_to_organization_with_all_sharding_columns.reload.organization_id)
        .to eq(organization.id)
      expect(batch_tracker_belonging_to_organization_with_all_sharding_columns.reload.namespace_id).to be_nil
      expect(batch_tracker_belonging_to_organization_with_all_sharding_columns.reload.project_id).to be_nil
    end
  end

  private

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS #{trigger_name} ON bulk_import_batch_trackers;

        ALTER TABLE bulk_import_batch_trackers DROP CONSTRAINT IF EXISTS #{constraint_name};
      SQL
    )
  end

  def add_constraint_and_trigger
    connection.execute(
      <<~SQL
        ALTER TABLE bulk_import_batch_trackers ADD CONSTRAINT #{constraint_name} CHECK ((num_nonnulls(namespace_id, organization_id, project_id) = 1)) NOT VALID;

        CREATE TRIGGER #{trigger_name} BEFORE INSERT OR UPDATE ON bulk_import_batch_trackers FOR EACH ROW EXECUTE FUNCTION #{function_name}();
      SQL
    )
  end
end
