# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Loose foreign keys deleted records routed by sharding key', feature_category: :database do
  include MigrationsHelpers

  def create_table_structure
    migration = ActiveRecord::Migration.new.extend(Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers)

    project_target = {
      table: 'loose_foreign_keys_project_deleted_records', column: 'project_id', source: 'project_id'
    }
    namespace_target = {
      table: 'loose_foreign_keys_namespace_deleted_records', column: 'namespace_id', source: 'namespace_id'
    }

    targets_by_table = {
      '_test_lfk_flow_sharded_parent' => [project_target, namespace_target],
      '_test_lfk_flow_partitioned_parent' => [project_target]
    }

    migration.define_singleton_method(:sharding_keys_for) { |table| targets_by_table.fetch(table.to_s, []) }

    migration.create_table(:_test_lfk_flow_sharded_parent) do |t|
      t.bigint :project_id
      t.bigint :namespace_id
    end
    migration.create_table(:_test_lfk_flow_cell_local_parent)

    migration.execute(<<~SQL)
      CREATE TABLE _test_lfk_flow_partitioned_parent (
        id serial NOT NULL,
        project_id bigint,
        partition_id integer NOT NULL,
        PRIMARY KEY (id, partition_id)
      ) PARTITION BY LIST (partition_id);

      CREATE TABLE #{partition_identifier}
        PARTITION OF _test_lfk_flow_partitioned_parent FOR VALUES IN (1);
    SQL

    child_tables.each { |child| migration.create_table(child) { |t| t.bigint :parent_id } }

    migration.track_record_deletions_with_sharding_keys(:_test_lfk_flow_sharded_parent)
    migration.track_record_deletions(:_test_lfk_flow_cell_local_parent)
    migration.track_record_deletions_override_table_name_with_sharding_keys(
      partition_identifier, :_test_lfk_flow_partitioned_parent
    )
  end

  def child_tables
    [
      :_test_lfk_flow_deleted_child,
      :_test_lfk_flow_nullified_child,
      :_test_lfk_flow_cell_local_child,
      :_test_lfk_flow_partitioned_child
    ]
  end

  def partition_identifier
    "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_lfk_flow_partitioned_parent_1"
  end

  let(:sharded_parent) { table(:_test_lfk_flow_sharded_parent) }
  let(:cell_local_parent) { table(:_test_lfk_flow_cell_local_parent) }
  let(:partitioned_parent) { table(:_test_lfk_flow_partitioned_parent) }
  let(:deleted_child) { table(:_test_lfk_flow_deleted_child) }
  let(:nullified_child) { table(:_test_lfk_flow_nullified_child) }
  let(:cell_local_child) { table(:_test_lfk_flow_cell_local_child) }
  let(:partitioned_child) { table(:_test_lfk_flow_partitioned_child) }

  let(:loose_foreign_key_definitions) do
    {
      '_test_lfk_flow_sharded_parent' => [
        loose_foreign_key(:_test_lfk_flow_deleted_child, :_test_lfk_flow_sharded_parent, :async_delete),
        loose_foreign_key(:_test_lfk_flow_nullified_child, :_test_lfk_flow_sharded_parent, :async_nullify)
      ],
      '_test_lfk_flow_cell_local_parent' => [
        loose_foreign_key(:_test_lfk_flow_cell_local_child, :_test_lfk_flow_cell_local_parent, :async_delete)
      ],
      '_test_lfk_flow_partitioned_parent' => [
        loose_foreign_key(:_test_lfk_flow_partitioned_child, :_test_lfk_flow_partitioned_parent, :async_delete)
      ]
    }
  end

  before_all do
    create_table_structure
  end

  before do
    allow(Gitlab::Database::LooseForeignKeys).to receive(:definitions_by_table)
      .and_return(loose_foreign_key_definitions)
  end

  it 'routes the deleted record by its sharding key and cleans the children up' do
    parent = sharded_parent.create!(project_id: 101)
    2.times { deleted_child.create!(parent_id: parent.id) }
    nullified_child.create!(parent_id: parent.id)

    sharded_parent.delete_all

    expect(LooseForeignKeys::ProjectDeletedRecord.pluck(:project_id)).to eq([101])
    expect(LooseForeignKeys::DeletedRecord.count).to eq(0)

    perform_cleanup

    expect(deleted_child.count).to eq(0)
    expect(nullified_child.where(parent_id: nil).count).to eq(1)
    expect(LooseForeignKeys::ProjectDeletedRecord.status_processed.count).to eq(1)
  end

  # A row carrying two sharding keys produces one record per key, so the worker consumes the same
  # deleted row twice. The children must still be cleaned, and both records must end up processed.
  it 'cleans the child up once when one row routes to two stores' do
    parent = sharded_parent.create!(project_id: 101, namespace_id: 9)
    deleted_child.create!(parent_id: parent.id)

    sharded_parent.delete_all

    expect(LooseForeignKeys::ProjectDeletedRecord.count).to eq(1)
    expect(LooseForeignKeys::NamespaceDeletedRecord.count).to eq(1)
    expect(LooseForeignKeys::DeletedRecord.count).to eq(0)

    perform_cleanup

    expect(deleted_child.count).to eq(0)
    expect(LooseForeignKeys::ProjectDeletedRecord.status_processed.count).to eq(1)
    expect(LooseForeignKeys::NamespaceDeletedRecord.status_processed.count).to eq(1)
  end

  it 'cleans the children up when one statement deletes rows with and without a sharding key' do
    with_key = sharded_parent.create!(project_id: 101)
    without_key = sharded_parent.create!(project_id: nil)
    deleted_child.create!(parent_id: with_key.id)
    deleted_child.create!(parent_id: without_key.id)

    sharded_parent.delete_all

    expect(LooseForeignKeys::ProjectDeletedRecord.count).to eq(1)
    expect(LooseForeignKeys::DeletedRecord.count).to eq(1)

    perform_cleanup

    expect(deleted_child.count).to eq(0)
  end

  it 'consumes records from the cell-local and the sharded stores in the same run' do
    sharded = sharded_parent.create!(project_id: 101)
    cell_local = cell_local_parent.create!
    deleted_child.create!(parent_id: sharded.id)
    cell_local_child.create!(parent_id: cell_local.id)

    sharded_parent.delete_all
    cell_local_parent.delete_all

    perform_cleanup

    expect(deleted_child.count).to eq(0)
    expect(cell_local_child.count).to eq(0)
  end

  it 'records the parent table name for a partitioned parent so the cleanup finds its definitions' do
    partitioned_parent.create!(project_id: 101, partition_id: 1)
    # The partitioned table has a composite primary key, so `id` on the record is an array.
    partitioned_child.create!(parent_id: partitioned_parent.pick(:id))

    delete_from_partition

    records = LooseForeignKeys::ProjectDeletedRecord.all
    expect(records.map(&:fully_qualified_table_name)).to(
      contain_exactly("#{current_schema}._test_lfk_flow_partitioned_parent")
    )

    perform_cleanup

    expect(partitioned_child.count).to eq(0)
  end

  it 'does not redo the work on a second run' do
    parent = sharded_parent.create!(project_id: 101)
    deleted_child.create!(parent_id: parent.id)
    sharded_parent.delete_all

    perform_cleanup

    expect { perform_cleanup }.not_to change { deleted_child.count }
    expect(LooseForeignKeys::ProjectDeletedRecord.status_pending.count).to eq(0)
  end

  def loose_foreign_key(child_table, parent_table, on_delete)
    ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
      child_table.to_s,
      parent_table.to_s,
      {
        column: 'parent_id',
        on_delete: on_delete,
        gitlab_schema: :gitlab_main,
        worker_class: LooseForeignKeys::CleanupWorker
      }
    )
  end

  def current_schema
    ApplicationRecord.connection.current_schema
  end

  def delete_from_partition
    ApplicationRecord.connection.execute("DELETE FROM #{partition_identifier}")
  end

  def perform_cleanup
    travel_to(Time.current.midnight) { LooseForeignKeys::CleanupWorker.new.perform }
  end
end
