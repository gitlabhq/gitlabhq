# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers, feature_category: :database do
  # `freeze: false` is kept here because this `let_it_be` subject is not an
  # ActiveRecord model record (it's an ActiveRecord::Migration instance extended
  # with the helpers module), so freezing
  # `refind` are no-ops on it. Keep as-is (see gitlab-org/gitlab#602925).
  let_it_be(:migration, freeze: false) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  # test tables must be prefixed with _test_gitlab_shared_cell_local_ to land on
  # gitlab_shared_cell_local schema. loose_foreign_keys_deleted_records belongs to gitlab_shared_cell_local
  let_it_be(:table_name) { :_test_gitlab_shared_cell_local_partitioned_loose_fk_table }

  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = :_test_gitlab_shared_cell_local_partitioned_loose_fk_table
    end
  end

  before(:all) do
    migration.create_table table_name do |t|
      t.timestamps
    end
  end

  after(:all) do
    migration.drop_table table_name
  end

  before do
    3.times { model.create! }
  end

  context 'when the record deletion tracker trigger is not installed' do
    it 'does store record deletions' do
      model.delete_all

      expect(LooseForeignKeys::DeletedRecord.count).to eq(0)
    end

    it { expect(migration.has_loose_foreign_key?(table_name)).to be_falsy }
  end

  context 'when the record deletion tracker trigger is installed' do
    before do
      migration.track_record_deletions(table_name)
    end

    it 'stores the record deletion' do
      records = model.all
      record_to_be_deleted = records.last

      record_to_be_deleted.delete

      expect(LooseForeignKeys::DeletedRecord.count).to eq(1)

      arel_table = LooseForeignKeys::DeletedRecord.arel_table
      deleted_record = LooseForeignKeys::DeletedRecord
        .select(arel_table[Arel.star], arel_table[:partition].as('partition_number')) # aliasing the ignored partition column to partition_number
        .all
        .first

      expect(deleted_record.primary_key_value).to eq(record_to_be_deleted.id)
      expect(deleted_record.fully_qualified_table_name).to eq("public.#{table_name}")
      expect(deleted_record.partition_number).to eq(1)
    end

    it 'stores multiple record deletions' do
      model.delete_all

      expect(LooseForeignKeys::DeletedRecord.count).to eq(3)
    end

    it { expect(migration.has_loose_foreign_key?(table_name)).to be_truthy }
  end

  context 'with partitioned tables' do
    let(:current_schema) { migration.connection.current_schema }
    let(:dynamic_partitions_schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }
    let(:partitioned_table) { :_test_gitlab_shared_cell_local_partitioned_loose_fk }
    let(:partitioned_table_identifier) { "#{current_schema}.#{partitioned_table}" }
    let(:partition) { :_test_gitlab_shared_cell_local_partition_01 }
    let(:partition_identifier) { "#{dynamic_partitions_schema}.#{partition}" }

    before do
      migration.connection.execute <<~SQL
        CREATE TABLE #{partitioned_table}(
          id serial not null,
          partition_id integer,
          primary key (id, partition_id)
        ) PARTITION BY LIST (partition_id);

        CREATE TABLE #{dynamic_partitions_schema}.#{partition} PARTITION OF #{partitioned_table}
        FOR VALUES IN (1);

        INSERT INTO #{partitioned_table}(id, partition_id) VALUES(1, 1);
        INSERT INTO #{partitioned_table}(id, partition_id) VALUES(2, 1);
        INSERT INTO #{partitioned_table}(id, partition_id) VALUES(3, 1);

        DELETE FROM loose_foreign_keys_deleted_records;
      SQL
    end

    after do
      migration.connection.execute <<~SQL
        DROP TABLE #{partitioned_table} CASCADE;
      SQL
    end

    it 'adds the loose foreign key trigger functionality to the partitioned table' do
      migration.track_record_deletions_override_table_name(partitioned_table_identifier)

      expect do
        migration.connection.execute("DELETE FROM #{partitioned_table}")
      end.to change {
        LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: partitioned_table_identifier).count
      }.by(3)
    end

    it 'adds the loose foreign key trigger functionality to the partition' do
      migration.track_record_deletions_override_table_name(partition_identifier, partitioned_table)

      expect do
        migration.connection.execute("DELETE FROM #{partition_identifier}")
      end.to change {
        # For partitions, we add the LFK deleted_records for the parent partitioned table
        LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: partitioned_table_identifier).count
      }.by(3)
    end

    it 'allows removing the loose foreign key trigger from partitions as well' do
      migration.track_record_deletions_override_table_name(partition_identifier, partitioned_table)
      migration.untrack_record_deletions(partition_identifier)

      expect do
        migration.connection.execute("DELETE FROM #{partition_identifier}")
      end.not_to change {
        LooseForeignKeys::DeletedRecord.where(fully_qualified_table_name: partitioned_table_identifier).count
      }
    end
  end

  context 'with custom column tracking' do
    let_it_be(:table_name) { :_test_gitlab_shared_cell_local_lfk_custom_col }
    let(:table_identifier) { "public.#{table_name}" }

    before do
      migration.connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.loose_foreign_keys_deleted_records_1
          PARTITION OF loose_foreign_keys_deleted_records FOR VALUES IN (1);
      SQL

      migration.connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          group_id serial NOT NULL PRIMARY KEY
        );

        INSERT INTO #{table_name} DEFAULT VALUES;
        INSERT INTO #{table_name} DEFAULT VALUES;
        INSERT INTO #{table_name} DEFAULT VALUES;

        DELETE FROM loose_foreign_keys_deleted_records;
      SQL
    end

    after do
      migration.connection.execute("DROP TABLE IF EXISTS #{table_name} CASCADE")
    end

    describe '#track_record_deletions_with_custom_column' do
      it 'stores deletions using the custom column value' do
        migration.track_record_deletions_with_custom_column(table_name, column: :group_id)

        expect do
          migration.connection.execute("DELETE FROM #{table_name}")
        end.to change {
          LooseForeignKeys::DeletedRecord.count
        }.by(3)
      end

      it 'accepts custom function and trigger names' do
        migration.track_record_deletions_with_custom_column(
          table_name, column: :group_id, function_name: 'lfk_custom_fn', trigger_name: 'custom_trigger'
        )

        expect do
          migration.connection.execute("DELETE FROM #{table_name}")
        end.to change {
          LooseForeignKeys::DeletedRecord.count
        }.by(3)
      end

      it 'raises when derived identifiers exceed 63 characters' do
        expect do
          migration.track_record_deletions_with_custom_column(
            :a_very_long_table_name_that_will_exceed_the_postgres_identifier_limit_of_63, column: :group_id
          )
        end.to raise_error(ArgumentError, /is too long/)
      end

      it 'raises when column is not unique' do
        migration.connection.execute(<<~SQL)
          CREATE TABLE _test_lfk_non_unique (
            id serial PRIMARY KEY,
            name text
          );
        SQL

        expect do
          migration.track_record_deletions_with_custom_column(:_test_lfk_non_unique, column: :name)
        end.to raise_error(ArgumentError, /must have a unique index/)
      ensure
        migration.connection.execute("DROP TABLE IF EXISTS _test_lfk_non_unique CASCADE")
      end

      it 'accepts a column with a unique index' do
        migration.connection.execute(<<~SQL)
          CREATE TABLE _test_gitlab_shared_cell_local_lfk_unique_idx (
            id serial PRIMARY KEY,
            external_id integer NOT NULL
          );

          CREATE UNIQUE INDEX ON _test_gitlab_shared_cell_local_lfk_unique_idx (external_id);

          INSERT INTO _test_gitlab_shared_cell_local_lfk_unique_idx (external_id) VALUES (10), (20), (30);
          DELETE FROM loose_foreign_keys_deleted_records;
        SQL

        migration.track_record_deletions_with_custom_column(:_test_gitlab_shared_cell_local_lfk_unique_idx, column: :external_id)

        expect do
          migration.connection.execute("DELETE FROM _test_gitlab_shared_cell_local_lfk_unique_idx")
        end.to change {
          LooseForeignKeys::DeletedRecord.count
        }.by(3)
      ensure
        migration.connection.execute("DROP TABLE IF EXISTS _test_gitlab_shared_cell_local_lfk_unique_idx CASCADE")
      end
    end

    describe '#untrack_record_deletions' do
      it 'stops tracking deletions when given a custom trigger name' do
        migration.track_record_deletions_with_custom_column(table_name, column: :group_id, trigger_name: "#{table_name}_loose_fk")
        migration.untrack_record_deletions(table_name, trigger_name: "#{table_name}_loose_fk")

        expect do
          migration.connection.execute("DELETE FROM #{table_name}")
        end.not_to change {
          LooseForeignKeys::DeletedRecord.count
        }
      end
    end

    context 'with partitioned tables' do
      let(:current_schema) { migration.connection.current_schema }
      let(:dynamic_partitions_schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }
      let(:partitioned_table) { :_test_gitlab_shared_cell_local_p_lfk_custom_col }
      let(:partitioned_table_identifier) { "#{current_schema}.#{partitioned_table}" }
      let(:partition) { :_test_gitlab_shared_cell_local_partition_cust_col_01 }
      let(:partition_identifier) { "#{dynamic_partitions_schema}.#{partition}" }

      before do
        migration.connection.execute(<<~SQL)
          CREATE TABLE #{partitioned_table} (
            group_id serial NOT NULL,
            partition_id integer NOT NULL,
            PRIMARY KEY (group_id, partition_id)
          ) PARTITION BY LIST (partition_id);

          CREATE TABLE #{dynamic_partitions_schema}.#{partition}
            PARTITION OF #{partitioned_table} FOR VALUES IN (1);

          CREATE UNIQUE INDEX ON #{dynamic_partitions_schema}.#{partition} (group_id);

          INSERT INTO #{partitioned_table} (partition_id) VALUES (1), (1), (1);
          DELETE FROM loose_foreign_keys_deleted_records;
        SQL
      end

      after do
        migration.connection.execute("DROP TABLE IF EXISTS #{partitioned_table} CASCADE")
      end

      it 'stores deletions from the partition with the parent table name' do
        migration.track_record_deletions_with_custom_column(
          partition_identifier, column: :group_id,
          parent_table: partitioned_table,
          function_name: 'lfk_custom_col_partition_fn', trigger_name: 'custom_col_partition_trigger'
        )

        expect do
          migration.connection.execute("DELETE FROM #{partition_identifier}")
        end.to change {
          LooseForeignKeys::DeletedRecord.count
        }.by(3)
      end
    end
  end

  describe '#partitioned_record_deletions_routed_by_sharding_keys?' do
    subject(:routed) { migration.partitioned_record_deletions_routed_by_sharding_keys?(table_name) }

    let(:targets_json) do
      '[{"table":"loose_foreign_keys_project_deleted_records","column":"project_id","source":"project_id"}]'
    end

    it 'is false when the table has no LFK trigger' do
      expect(routed).to be(false)
    end

    it 'is false for the plain trigger without arguments' do
      migration.track_record_deletions(table_name)

      expect(routed).to be(false)
    end

    it 'is false for the override trigger carrying only the table name' do
      migration.track_record_deletions_override_table_name(table_name)

      expect(routed).to be(false)
    end

    # The regular-table function on a partitioned parent is an invalid setup, in or out
    # of the Cells context; the predicate only recognizes the override-table function.
    it 'is false for the regular-table trigger even when it carries a targets argument' do
      migration.connection.execute(<<~SQL)
        CREATE TRIGGER #{table_name}_loose_fk_trigger
        AFTER DELETE ON #{table_name} REFERENCING OLD TABLE AS old_table
        FOR EACH STATEMENT
        EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records('#{targets_json}');
      SQL

      expect(routed).to be(false)
    end

    it 'is true for the override trigger carrying a targets argument' do
      migration.connection.execute(<<~SQL)
        CREATE TRIGGER #{table_name}_loose_fk_trigger
        AFTER DELETE ON #{table_name} REFERENCING OLD TABLE AS old_table
        FOR EACH STATEMENT
        EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records_override_table('#{table_name}', '#{targets_json}');
      SQL

      expect(routed).to be(true)
    end
  end

  describe '#sharding_keys_for' do
    it 'resolves a sharding key referencing projects to the project deleted-records table' do
      expect(migration.sharding_keys_for('project_repositories')).to contain_exactly(
        { table: 'loose_foreign_keys_project_deleted_records', column: 'project_id', source: 'project_id' }
      )
    end

    it 'resolves by the referenced table, not the source column name' do
      stub_sharding_key('_test_lfk_group_table', 'group_id' => 'namespaces')

      expect(migration.sharding_keys_for('_test_lfk_group_table')).to contain_exactly(
        { table: 'loose_foreign_keys_namespace_deleted_records', column: 'namespace_id', source: 'group_id' }
      )
    end

    it 'returns an empty array for a table without a sharding key' do
      expect(migration.sharding_keys_for('loose_foreign_keys_deleted_records')).to eq([])
    end

    it 'ignores sharding keys referencing non-routable tables' do
      stub_sharding_key('_test_lfk_ci_table', 'pipeline_id' => 'ci_pipelines')

      expect(migration.sharding_keys_for('_test_lfk_ci_table')).to eq([])
    end

    it 'raises when two sharding keys route to the same table' do
      stub_sharding_key('_test_lfk_ambiguous_table', 'group_id' => 'namespaces', 'namespace_id' => 'namespaces')

      expect { migration.sharding_keys_for('_test_lfk_ambiguous_table') }.to raise_error(
        ArgumentError, /more than one sharding key routed to loose_foreign_keys_namespace_deleted_records/
      )
    end
  end

  describe '#sharding_keys_args' do
    it 'returns a quoted JSON literal of the routing targets' do
      targets = [{ table: 'loose_foreign_keys_project_deleted_records', column: 'project_id', source: 'project_id' }]

      expect(migration.sharding_keys_args('project_repositories')).to(eq(migration.connection.quote(targets.to_json)))
    end

    it 'returns nil when there are no routable sharding keys' do
      expect(migration.sharding_keys_args('loose_foreign_keys_deleted_records')).to be_nil
    end

    it 'raises when the declared sharding key column is missing from the table' do
      stub_sharding_key('project_repositories', 'nonexistent_id' => 'projects')

      expect { migration.sharding_keys_args('project_repositories') }.to raise_error(
        ArgumentError, /missing the sharding key column\(s\) nonexistent_id/
      )
    end

    it 'raises when the target deleted-records table does not exist' do
      stub_const(
        "#{described_class}::SHARDING_KEY_TARGETS",
        { 'projects' => { table: '_test_lfk_no_such_deleted_records', column: 'project_id' } }
      )

      expect { migration.sharding_keys_args('project_repositories') }.to raise_error(
        ArgumentError,
        /Missing loose foreign keys deleted-records target\(s\) _test_lfk_no_such_deleted_records.project_id/
      )
    end
  end

  describe 'sharding key routing' do
    let(:current_schema) { migration.connection.current_schema }
    let(:dynamic_partitions_schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }
    let(:sharding_keys) do
      %w[organization namespace project user].map do |key|
        { table: "loose_foreign_keys_#{key}_deleted_records", column: "#{key}_id", source: "#{key}_id" }
      end
    end

    before do
      create_deleted_records_partitions
      clear_deleted_records
    end

    after do
      clear_deleted_records
    end

    # Runs against both trigger functions. The routing logic is duplicated between
    # insert_into_loose_foreign_keys_deleted_records and its _override_table variant
    # because a transition table cannot be passed to another function, so both have
    # to be held to the same behavior here.
    shared_examples 'routing deleted records by sharding key' do
      before do
        allow(migration).to receive(:sharding_keys_for).and_return(sharding_keys)
      end

      it 'writes one record per sharding key the row carries' do
        insert_rows({ organization_id: 1, namespace_id: 2, project_id: 3, user_id: 4 })
        install_trigger

        delete_rows

        expect(records_per_store).to eq(cell_local: 0, organization: 1, namespace: 1, project: 1, user: 1)
      end

      it 'routes each row by the sharding keys it actually carries' do
        insert_rows({ project_id: 3 }, { namespace_id: 2 }, { organization_id: 1, user_id: 4 })
        install_trigger

        delete_rows

        expect(records_per_store).to eq(cell_local: 0, organization: 1, namespace: 1, project: 1, user: 1)
      end

      it 'keeps rows carrying no sharding key value in the cell-local table' do
        insert_rows({ project_id: 3 }, {}, {})
        install_trigger

        delete_rows

        expect(records_per_store).to eq(cell_local: 2, organization: 0, namespace: 0, project: 1, user: 0)
      end

      it 'accounts for every deleted row' do
        insert_rows({ project_id: 3 }, {}, { namespace_id: 2, project_id: 3 }, { user_id: 4 })
        install_trigger
        deleted_ids = current_ids

        delete_rows

        expect(tracked_row_ids).to match_array(deleted_ids)
        expect(records_per_store.values.sum).to eq(5)
      end

      it 'treats zero and negative sharding key values as present' do
        insert_rows({ project_id: 0 }, { project_id: -1 })
        install_trigger

        delete_rows

        expect(records_per_store).to eq(cell_local: 0, organization: 0, namespace: 0, project: 2, user: 0)
      end

      it 'writes nothing when the statement deletes no rows' do
        insert_rows({ project_id: 3 })
        install_trigger

        delete_rows('id < 0')

        expect(records_per_store.values).to all(eq(0))
      end

      it 'accumulates records across separate delete statements' do
        insert_rows({ project_id: 3 }, { project_id: 4 }, {})
        install_trigger

        current_ids.each { |id| delete_rows("id = #{id}") }

        expect(records_per_store).to eq(cell_local: 1, organization: 0, namespace: 0, project: 2, user: 0)
      end

      it 'records the tracked table name on every record' do
        insert_rows({ project_id: 3 }, {})
        install_trigger

        delete_rows

        expect(tracked_table_names).to eq([expected_table_name])
      end

      context 'when the table has no routable sharding key' do
        let(:sharding_keys) { [] }

        it 'keeps every deletion in the cell-local table' do
          insert_rows({ project_id: 3 }, {})
          install_trigger

          delete_rows

          expect(records_per_store).to eq(cell_local: 2, organization: 0, namespace: 0, project: 0, user: 0)
        end
      end
    end

    describe '#track_record_deletions_with_sharding_keys' do
      let(:table_name) { :_test_gitlab_shared_cell_local_lfk_sharded }
      let(:insert_target) { table_name }
      let(:delete_target) { table_name }
      let(:extra_insert_attributes) { {} }
      let(:expected_table_name) { "#{current_schema}.#{table_name}" }

      before do
        migration.connection.execute(<<~SQL)
          CREATE TABLE #{table_name} (
            id serial PRIMARY KEY,
            organization_id bigint,
            namespace_id bigint,
            project_id bigint,
            user_id bigint
          );
        SQL
      end

      after do
        migration.connection.execute("DROP TABLE IF EXISTS #{table_name} CASCADE")
      end

      it_behaves_like 'routing deleted records by sharding key'

      it 'rewrites an existing cell-local trigger in place' do
        allow(migration).to receive(:sharding_keys_for).and_return(sharding_keys)
        migration.track_record_deletions(table_name)
        insert_rows({ project_id: 3 })

        install_trigger
        delete_rows

        expect(records_per_store).to eq(cell_local: 0, organization: 0, namespace: 0, project: 1, user: 0)
      end

      # organizations is tracked with `sharding_key: { id: organizations }`, so the value routed
      # to the sharded table is the deleted row's own primary key.
      it 'routes a table whose sharding key is its own primary key' do
        allow(migration).to receive(:sharding_keys_for).and_return(
          [{ table: 'loose_foreign_keys_organization_deleted_records', column: 'organization_id', source: 'id' }]
        )
        insert_rows({ project_id: 3 }, {})
        install_trigger
        deleted_ids = current_ids

        delete_rows

        expect(records_per_store).to eq(cell_local: 0, organization: 2, namespace: 0, project: 0, user: 0)
        expect(LooseForeignKeys::OrganizationDeletedRecord.pluck(:primary_key_value, :organization_id)).to(
          match_array(deleted_ids.map { |id| [id, id] })
        )
      end

      it 'leaves the existing trigger in place when validation fails' do
        allow(migration).to receive(:sharding_keys_for).and_return(
          [{ table: '_test_lfk_no_such_deleted_records', column: 'project_id', source: 'project_id' }]
        )
        migration.track_record_deletions(table_name)
        insert_rows({ project_id: 3 })

        expect { install_trigger }.to raise_error(ArgumentError, /Missing loose foreign keys deleted-records target/)

        delete_rows

        expect(records_per_store).to eq(cell_local: 1, organization: 0, namespace: 0, project: 0, user: 0)
      end

      it 'fails loudly when the trigger names a target table that does not exist' do
        insert_rows({ project_id: 3 })

        migration.connection.execute(<<~SQL.squish)
          CREATE TRIGGER #{table_name}_loose_fk_trigger
          AFTER DELETE ON #{table_name} REFERENCING OLD TABLE AS old_table
          FOR EACH STATEMENT
          EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records(
            '[{"table":"_test_lfk_no_such_table","column":"project_id","source":"project_id"}]'
          );
        SQL

        expect do
          migration.connection.transaction(requires_new: true) { delete_rows }
        end.to raise_error(ActiveRecord::StatementInvalid, /relation "_test_lfk_no_such_table" does not exist/)
      end

      def install_trigger
        migration.track_record_deletions_with_sharding_keys(table_name)
      end
    end

    describe '#track_record_deletions_override_table_name_with_sharding_keys' do
      let(:partitioned_table) { :_test_gitlab_shared_cell_local_lfk_sharded_part }
      let(:partition) { :_test_gitlab_shared_cell_local_lfk_sharded_partition_01 }
      let(:insert_target) { partitioned_table }
      let(:delete_target) { "#{dynamic_partitions_schema}.#{partition}" }
      let(:extra_insert_attributes) { { partition_id: 1 } }
      let(:expected_table_name) { "#{current_schema}.#{partitioned_table}" }

      before do
        migration.connection.execute(<<~SQL)
          CREATE TABLE #{partitioned_table} (
            id serial NOT NULL,
            organization_id bigint,
            namespace_id bigint,
            project_id bigint,
            user_id bigint,
            partition_id integer NOT NULL,
            PRIMARY KEY (id, partition_id)
          ) PARTITION BY LIST (partition_id);

          CREATE TABLE #{dynamic_partitions_schema}.#{partition}
            PARTITION OF #{partitioned_table} FOR VALUES IN (1);
        SQL
      end

      after do
        migration.connection.execute("DROP TABLE IF EXISTS #{partitioned_table} CASCADE")
      end

      it_behaves_like 'routing deleted records by sharding key'

      def install_trigger
        migration.track_record_deletions_override_table_name_with_sharding_keys(delete_target, partitioned_table)
      end
    end

    def deleted_record_stores
      {
        cell_local: LooseForeignKeys::DeletedRecord,
        organization: LooseForeignKeys::OrganizationDeletedRecord,
        namespace: LooseForeignKeys::NamespaceDeletedRecord,
        project: LooseForeignKeys::ProjectDeletedRecord,
        user: LooseForeignKeys::UserDeletedRecord
      }
    end

    def create_deleted_records_partitions
      deleted_record_stores.each_value do |store|
        migration.connection.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS #{dynamic_partitions_schema}.#{store.table_name}_1
            PARTITION OF #{store.table_name} FOR VALUES IN (1);
        SQL
      end
    end

    def clear_deleted_records
      deleted_record_stores.each_value do |store|
        migration.connection.execute("DELETE FROM #{store.table_name}")
      end
    end

    def records_per_store
      deleted_record_stores.transform_values(&:count)
    end

    def tracked_row_ids
      deleted_record_stores.each_value.flat_map { |store| store.pluck(:primary_key_value) }.uniq
    end

    def tracked_table_names
      deleted_record_stores.each_value.flat_map { |store| store.pluck(:fully_qualified_table_name) }.uniq
    end

    def insert_rows(*rows)
      rows.each do |row|
        attributes = row.merge(extra_insert_attributes)

        if attributes.empty?
          migration.connection.execute("INSERT INTO #{insert_target} DEFAULT VALUES")
        else
          values = attributes.values.map { |value| migration.connection.quote(value) }

          migration.connection.execute(
            "INSERT INTO #{insert_target} (#{attributes.keys.join(', ')}) VALUES (#{values.join(', ')})"
          )
        end
      end
    end

    def delete_rows(condition = nil)
      migration.connection.execute("DELETE FROM #{delete_target}#{" WHERE #{condition}" if condition}")
    end

    def current_ids
      migration.connection.select_values("SELECT id FROM #{delete_target} ORDER BY id")
    end
  end

  def stub_sharding_key(table_name, sharding_key)
    entry = instance_double(Gitlab::Database::Dictionary::Entry, sharding_key: sharding_key)

    allow(Gitlab::Database::Dictionary.entries).to receive(:find_by_table_name).and_call_original
    allow(Gitlab::Database::Dictionary.entries).to receive(:find_by_table_name)
      .with(table_name).and_return(entry)
  end
end
