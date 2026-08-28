# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionManager, feature_category: :database do
  include ActiveSupport::Testing::TimeHelpers
  include Database::PartitioningHelpers
  include Database::TriggerHelpers
  include ExclusiveLeaseHelpers
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers
  using RSpec::Parameterized::TableSyntax

  let(:partitioned_table_name) { :_test_gitlab_main_my_model_example_table }

  context 'creating partitions (mocked)' do
    subject(:sync_partitions) { manager.sync_partitions }

    let(:manager) { described_class.new(model) }
    let(:model) { double(partitioning_strategy: partitioning_strategy, table_name: table, connection: connection) }
    let(:connection) { ActiveRecord::Base.connection }
    let(:table) { partitioned_table_name }
    let(:partitioning_strategy) do
      double(missing_partitions: partitions, extra_partitions: [], after_adding_partitions: nil, analyze_interval: nil)
    end

    let(:partitions) do
      [
        instance_double(Gitlab::Database::Partitioning::TimePartition,
          table: 'bar',
          partition_name: 'foo',
          to_create_sql: "CREATE TABLE _partition_1",
          to_attach_sql: "ALTER TABLE foo ATTACH PARTITION _partition_1"),
        instance_double(Gitlab::Database::Partitioning::TimePartition,
          table: 'bar',
          partition_name: 'foo2',
          to_create_sql: "CREATE TABLE _partition_2",
          to_attach_sql: "ALTER TABLE foo2 ATTACH PARTITION _partition_2")
      ]
    end

    context 'when the given table is partitioned' do
      before do
        create_partitioned_table(connection, table)

        allow(connection).to receive(:table_exists?).and_call_original
        allow(connection).to receive(:table_exists?).with(table).and_return(true)
        allow(connection).to receive(:execute).and_call_original
        expect(partitioning_strategy).to receive(:validate_and_fix)

        stub_exclusive_lease(described_class::MANAGEMENT_LEASE_KEY % table, timeout: described_class::LEASE_TIMEOUT)
      end

      it 'creates and attaches the partition in 2 steps', :aggregate_failures do
        expect(connection).not_to receive(:execute).with("LOCK TABLE \"#{table}\" IN ACCESS EXCLUSIVE MODE")
        expect(manager).to receive(:create_partition_tables).with(partitions)
        expect(manager).to receive(:attach_partition_tables).with(partitions)

        sync_partitions
      end

      context 'with explicitly provided connection' do
        let(:connection) { Ci::ApplicationRecord.connection }
        let(:manager) { described_class.new(model, connection: connection) }

        it 'uses the explicitly provided connection when any', :aggregate_failures do
          skip_if_multiple_databases_not_setup(:ci)

          expect(manager).to receive(:create_partition_tables).with(partitions)
          expect(manager).to receive(:attach_partition_tables).with(partitions)

          sync_partitions
        end
      end

      context 'when an ArgumentError occurs during partition management' do
        it 'raises error' do
          expect(partitioning_strategy).to receive(:missing_partitions).and_raise(ArgumentError)

          expect { sync_partitions }.to raise_error(ArgumentError)
        end
      end

      context 'when an error occurs during partition management' do
        it 'does not raise an error' do
          expect(partitioning_strategy).to receive(:missing_partitions).and_raise('this should never happen (tm)')

          expect { sync_partitions }.not_to raise_error
        end
      end
    end

    context 'when the table is not partitioned' do
      let(:table) { 'this_does_not_need_to_be_real_table' }

      it 'does not try creating the partitions' do
        expect(connection).not_to receive(:execute).with("LOCK TABLE \"#{table}\" IN ACCESS EXCLUSIVE MODE")
        expect(Gitlab::AppLogger).to receive(:warn).with(
          {
            message: 'Skipping syncing partitions',
            table_name: table,
            connection_name: 'main'
          }
        )

        sync_partitions
      end
    end
  end

  context 'creating partitions' do
    subject(:sync_partitions) { described_class.new(my_model).sync_partitions }

    let(:connection) { ActiveRecord::Base.connection }
    let(:my_model) do
      Class.new(ApplicationRecord) do
        include PartitionedTable

        partitioned_by :created_at, strategy: :monthly, retain_for: :ever
      end
    end

    context 'when single database is configured' do
      before do
        skip_if_database_exists(:ci)

        my_model.table_name = partitioned_table_name

        create_partitioned_table(connection, partitioned_table_name)
      end

      it 'creates partitions' do
        expect { sync_partitions }.to change { find_partitions(my_model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA).size }.from(0)
      end
    end

    context 'when partitioned table has a loose foreign key trigger' do
      before do
        my_model.table_name = partitioned_table_name
        create_partitioned_table(connection, partitioned_table_name)

        track_record_deletions(my_model.table_name)
      end

      it 'attaches LFK trigger on the newly created partitions' do
        expect(trigger_exists?(my_model.table_name, record_deletion_trigger_name(my_model.table_name))).to be(true)

        expect { sync_partitions }.to change {
          find_partitions(my_model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA).size
        }.from(0)

        partitions = find_partitions(my_model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)
        partitions.each do |partition|
          partition_name = partition.first
          expect(trigger_exists?(partition_name, record_deletion_trigger_name(partition_name), Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)).to be(true)
        end
      end
    end

    context 'when the partitioned table routes deleted records by sharding keys' do
      # Three targets, one with source different from the target column, mirroring the richest
      # real case (clusters: group_id routes to namespace_id).
      let(:sharding_key_targets) do
        [
          { table: 'loose_foreign_keys_project_deleted_records', column: 'project_id', source: 'project_id' },
          { table: 'loose_foreign_keys_namespace_deleted_records', column: 'namespace_id', source: 'group_id' },
          { table: 'loose_foreign_keys_organization_deleted_records', column: 'organization_id',
            source: 'organization_id' }
        ]
      end

      let(:targets_json) { sharding_key_targets.to_json }

      before do
        my_model.table_name = partitioned_table_name
        create_partitioned_table(connection, partitioned_table_name)

        connection.execute(<<~SQL)
          ALTER TABLE #{partitioned_table_name}
            ADD COLUMN project_id bigint,
            ADD COLUMN group_id bigint,
            ADD COLUMN organization_id bigint;

          CREATE TRIGGER #{record_deletion_trigger_name(partitioned_table_name)}
          AFTER DELETE ON #{partitioned_table_name} REFERENCING OLD TABLE AS old_table
          FOR EACH STATEMENT
          EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records_override_table('#{partitioned_table_name}', '#{targets_json}');
        SQL

        allow_next_instance_of(described_class) do |manager|
          allow(manager).to receive(:sharding_keys_for).and_return(sharding_key_targets)
        end
      end

      it 'attaches routed LFK triggers on the newly created partitions' do
        expect { sync_partitions }.to change {
          find_partitions(my_model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA).size
        }.from(0)

        partitions = find_partitions(my_model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)
        partitions.each do |partition|
          partition_name = partition.first
          action_statement = find_trigger_def(partition_name, record_deletion_trigger_name(partition_name))['action_statement']

          expect(action_statement).to include('insert_into_loose_foreign_keys_deleted_records_override_table')
          expect(action_statement).to include("'#{partitioned_table_name}'")
          expect(action_statement).to include(targets_json)
        end
      end
    end

    context 'when multiple databases are configured' do
      before do
        skip_if_shared_database(:ci)

        my_model.table_name = partitioned_table_name

        create_partitioned_table(connection, partitioned_table_name)

        stub_feature_flags(automatic_lock_writes_on_table: ff_enabled)
      end

      where(:gitlab_schema, :database, :expectation) do
        :gitlab_main | :main | false
        :gitlab_main | :ci   | true
        :gitlab_ci   | :main | true
        :gitlab_ci   | :ci   | false
      end
      with_them do
        subject(:sync_partitions) { described_class.new(my_model, connection: connection).sync_partitions }

        let(:partitioned_table_name) { "_test_gitlab_#{database}_my_model_example_#{gitlab_schema}" }
        let(:base_model) { Gitlab::Database.schemas_to_base_models[gitlab_schema].first }
        let(:connection) { Gitlab::Database.database_base_models[database.to_s].connection }

        let(:my_model) do
          Class.new(base_model) do
            include PartitionedTable

            partitioned_by :created_at, strategy: :monthly, retain_for: :ever
          end
        end

        let(:partitions) do
          Gitlab::Database::PostgresPartition.using_connection(connection) { Gitlab::Database::PostgresPartition.for_parent_table(partitioned_table_name).to_a }
        end

        let(:partitions_locked_for_writes?) do
          partitions.map do |partition|
            Gitlab::Database::LockWritesManager.new(
              table_name: "#{partition.schema}.#{partition.name}",
              connection: connection,
              database_name: gitlab_schema
            ).table_locked_for_writes?
          end.all?(true)
        end

        context 'when feature flag is enabled' do
          let(:ff_enabled) { true }

          it "matches expectation" do
            sync_partitions

            expect(partitions_locked_for_writes?).to eq(expectation)
          end
        end

        context 'when feature flag is disabled' do
          let(:ff_enabled) { false }

          it "does not lock created partition" do
            sync_partitions

            expect(partitions_locked_for_writes?).to be(false)
          end
        end
      end
    end
  end

  context 'detaching partitions' do
    subject(:sync_partitions) { manager.sync_partitions }

    let(:manager) { described_class.new(model) }
    let(:model) { double(partitioning_strategy: partitioning_strategy, table_name: table, connection: connection) }
    let(:connection) { ActiveRecord::Base.connection }
    let(:table) { :_test_foo }
    let(:partitioning_strategy) do
      double(extra_partitions: extra_partitions, missing_partitions: [], after_adding_partitions: nil, analyze_interval: nil)
    end

    let(:extra_partitions) do
      [
        instance_double(Gitlab::Database::Partitioning::TimePartition, table: table, partition_name: 'foo1', to_detach_sql: 'SELECT 1'),
        instance_double(Gitlab::Database::Partitioning::TimePartition, table: table, partition_name: 'foo2', to_detach_sql: 'SELECT 2')
      ]
    end

    before do
      create_parent_table

      allow(connection).to receive(:table_exists?).and_call_original
      allow(connection).to receive(:table_exists?).with(table).and_return(true)
      expect(partitioning_strategy).to receive(:validate_and_fix)

      stub_exclusive_lease(described_class::MANAGEMENT_LEASE_KEY % table, timeout: described_class::LEASE_TIMEOUT)
    end

    def create_parent_table
      create_partitioned_table(connection, table)
    end

    it 'detaches each extra partition' do
      extra_partitions.each { |p| expect(manager).to receive(:detach_one_partition).with(p) }

      sync_partitions
    end

    context 'when the eligibility check hits a database error' do
      before do
        allow_next_instances_of(Gitlab::Database::Partitioning::DetachEligibility, extra_partitions.size) do |check|
          allow(check).to receive(:detachable?).and_raise(ActiveRecord::StatementInvalid, 'statement timeout')
        end
      end

      it 'does not detach the partitions' do
        expect { sync_partitions }.not_to change { Postgresql::DetachedPartition.count }
      end

      it 'logs the error against each partition' do
        allow(Gitlab::AppLogger).to receive(:error)

        extra_partitions.each do |partition|
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(
              message: 'Deferred detaching partition',
              deferral_reason: :database_error,
              exception_message: /statement timeout/,
              partition_name: partition.partition_name
            )
          )
        end

        sync_partitions
      end
    end

    context 'when a partition is not detachable' do
      let(:blocker_level) { :warn }
      let(:blocker) do
        Gitlab::Database::Partitioning::DetachEligibility::Blocker.new(
          reason: :referencing_table_cannot_prune, level: blocker_level,
          details: { referencing_table: 'public._test_bar', foreign_key_name: 'fk_test_referencing' }
        )
      end

      before do
        allow_next_instances_of(Gitlab::Database::Partitioning::DetachEligibility, extra_partitions.size) do |check|
          allow(check).to receive_messages(detachable?: false, blocker: blocker)
        end
      end

      it 'defers every partition without opening a transaction' do
        expect(Gitlab::Database::Partitioning::WithPartitioningLockRetries).not_to receive(:new)

        expect { sync_partitions }.not_to change { Postgresql::DetachedPartition.count }
      end

      it 'logs each deferral with the details of its blocker' do
        allow(Gitlab::AppLogger).to receive(:warn)

        extra_partitions.each do |partition|
          expect(Gitlab::AppLogger).to receive(:warn).with({
            message: 'Deferred detaching partition',
            deferral_reason: :referencing_table_cannot_prune,
            partition_name: partition.partition_name,
            table_name: table,
            connection_name: 'main',
            referencing_table: 'public._test_bar',
            foreign_key_name: 'fk_test_referencing'
          })
        end

        sync_partitions
      end

      context 'when the blocker asks for another log level' do
        where(:blocker_level, :log_method) do
          :info  | :info
          :error | :error
        end

        with_them do
          it 'logs the deferrals at that level' do
            allow(Gitlab::AppLogger).to receive(log_method)

            extra_partitions.each do |partition|
              expect(Gitlab::AppLogger).to receive(log_method).with(
                hash_including(
                  deferral_reason: :referencing_table_cannot_prune,
                  partition_name: partition.partition_name
                )
              )
            end

            sync_partitions
          end
        end
      end
    end

    # End-to-end safety net: everything above stubs the check, and the reasons themselves are covered
    # in detach_eligibility_spec.rb
    context 'when a partitioned table references the parent table' do
      let(:table) { :_test_gitlab_main_referenced_parent }
      let(:referencing_table) { :_test_gitlab_main_referencing_parent }
      let(:dynamic_schema) { Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA }

      let(:extra_partitions) do
        [100, 101].map do |partition_id|
          Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
            table, [partition_id], partition_name: "#{table}_#{partition_id}"
          )
        end
      end

      # The referencing table is partitioned on the same key and has nothing detached, so the two
      # partitions differ only in whether their counterpart is still attached: 101's is, 100's is not
      def create_parent_table
        connection.execute(<<~SQL)
          CREATE TABLE #{table} (
            partition_id bigint NOT NULL,
            id bigserial NOT NULL,
            PRIMARY KEY (partition_id, id)
          ) PARTITION BY LIST (partition_id);

          CREATE TABLE #{dynamic_schema}.#{table}_100
            PARTITION OF #{table} FOR VALUES IN (100);

          CREATE TABLE #{dynamic_schema}.#{table}_101
            PARTITION OF #{table} FOR VALUES IN (101);

          CREATE TABLE #{referencing_table} (
            partition_id bigint NOT NULL,
            id bigserial NOT NULL,
            referenced_id bigint NOT NULL,
            PRIMARY KEY (partition_id, id),
            CONSTRAINT fk_test_referencing FOREIGN KEY (partition_id, referenced_id)
              REFERENCES #{table} (partition_id, id)
          ) PARTITION BY LIST (partition_id);

          CREATE TABLE #{dynamic_schema}.#{referencing_table}_101
            PARTITION OF #{referencing_table} FOR VALUES IN (101);
        SQL
      end

      it 'detaches only the partition that satisfies every condition' do
        sync_partitions

        expect(find_partitions(table).flatten).to contain_exactly("#{table}_101")
      end

      it 'keeps the cleanup record of the partition it detached' do
        sync_partitions

        expect(Postgresql::DetachedPartition.pluck(:table_name)).to contain_exactly("#{table}_100")
      end
    end
  end

  describe '#detach_partitions' do
    around do |ex|
      travel_to(Date.parse('2021-06-23')) do
        ex.run
      end
    end

    subject { described_class.new(my_model).sync_partitions }

    let(:connection) { ActiveRecord::Base.connection }
    let(:my_model) do
      Class.new(ApplicationRecord) do
        include PartitionedTable

        partitioned_by :created_at, strategy: :monthly, retain_for: 1.month
      end
    end

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{partitioned_table_name}
        (id serial not null, created_at timestamptz not null, primary key (id, created_at))
        PARTITION BY RANGE (created_at);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partitioned_table_name}_202104
        PARTITION OF #{partitioned_table_name}
        FOR VALUES FROM ('2021-04-01') TO ('2021-05-01');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partitioned_table_name}_202105
        PARTITION OF #{partitioned_table_name}
        FOR VALUES FROM ('2021-05-01') TO ('2021-06-01');
      SQL

      my_model.table_name = partitioned_table_name

      # Also create all future partitions so that the sync is only trying to detach old partitions
      my_model.partitioning_strategy.missing_partitions.each do |p|
        connection.execute p.to_create_sql
        connection.execute p.to_attach_sql
      end
    end

    def num_tables
      connection.select_value(<<~SQL)
        SELECT COUNT(*)
        FROM pg_class
        where relkind IN ('r', 'p')
      SQL
    end

    it 'detaches exactly one partition' do
      expect { subject }.to change { find_partitions(my_model.table_name).size }.from(9).to(8)
    end

    it 'detaches the old partition' do
      expect { subject }.to change { has_partition(my_model, 2.months.ago.beginning_of_month) }.from(true).to(false)
    end

    it 'deletes zero tables' do
      expect { subject }.not_to change { num_tables }
    end

    it 'creates the appropriate PendingPartitionDrop entry' do
      subject

      pending_drop = Postgresql::DetachedPartition.find_by!(table_name: "#{partitioned_table_name}_202104")
      expect(pending_drop.drop_after).to eq(Time.current + described_class::RETAIN_DETACHED_PARTITIONS_FOR)
    end

    context 'when the model overrides the detached partition retention period' do
      let(:my_model) do
        Class.new(ApplicationRecord) do
          include PartitionedTable

          partitioned_by :created_at, strategy: :monthly, retain_for: 1.month,
            retain_detached_partitions_for: 3.days
        end
      end

      it 'uses the model-specific retention period for the drop_after timestamp' do
        subject

        pending_drop = Postgresql::DetachedPartition.find_by!(table_name: "#{partitioned_table_name}_202104")
        expect(pending_drop.drop_after).to eq(Time.current + 3.days)
      end
    end

    context 'when the model is the target of a foreign key' do
      before do
        connection.execute(<<~SQL)
        create unique index idx_for_fk ON #{partitioned_table_name}(created_at);

        create table _test_gitlab_main_referencing_table (
          id bigserial primary key not null,
          referencing_created_at timestamptz references #{partitioned_table_name}(created_at)
        );
        SQL
      end

      it 'does not detach partitions with a referenced foreign key' do
        expect { subject }.not_to change { find_partitions(my_model.table_name).size }
      end
    end

    context 'when scheduling partition drops for large partitions' do
      before do
        stub_const("#{described_class}::MAX_PARTITION_SIZE", 1.byte)

        connection.execute(<<~SQL)
          INSERT INTO #{partitioned_table_name} (created_at) VALUES ('2021-04-15');
        SQL
      end

      it 'schedules large partitions for weekend drops' do
        next_saturday = Date.parse('2021-07-03')

        expect(Postgresql::DetachedPartition).to receive(:create!)
          .with(table_name: "#{partitioned_table_name}_202104", drop_after: next_saturday)

        subject
      end
    end
  end

  describe 'analyze partitioned table' do
    let(:analyze) { true }
    let(:analyze_table) { partitioned_table_name }
    let(:analyze_partition) { "#{partitioned_table_name}_1" }
    let(:analyze_regex) { /ANALYZE \(SKIP_LOCKED\) "#{analyze_table}"/ }
    let(:analyze_interval) { 1.week }
    let(:connection) { my_model.connection }
    let(:create_partition) { true }
    let(:my_model) do
      interval = analyze_interval
      Class.new(ApplicationRecord) do
        include PartitionedTable

        partitioned_by :partition_id,
          strategy: :ci_sliding_list,
          next_partition_if: proc { false },
          detach_partition_if: proc { false },
          analyze_interval: interval
      end
    end

    shared_examples_for 'run only once analyze within interval' do
      before do
        allow_next_instance_of(described_class) do |instance|
          # Checking of LFK trigger affects the analyze tests
          allow(instance).to receive(:parent_table_has_loose_foreign_key?).and_return(false)
        end
      end

      specify do
        control = ActiveRecord::QueryRecorder.new { described_class.new(my_model, connection: connection).sync_partitions(analyze: analyze) }
        expect(control.occurrences).to include(analyze_regex)

        control = ActiveRecord::QueryRecorder.new { described_class.new(my_model, connection: connection).sync_partitions(analyze: analyze) }
        expect(control.occurrences).not_to include(analyze_regex)

        travel_to((analyze_interval * 2).since) do
          control = ActiveRecord::QueryRecorder.new { described_class.new(my_model, connection: connection).sync_partitions(analyze: analyze) }
          expect(control.occurrences).to include(analyze_regex)
        end
      end
    end

    shared_examples_for 'not to run the analyze at all' do
      specify do
        control = ActiveRecord::QueryRecorder.new { described_class.new(my_model, connection: connection).sync_partitions(analyze: analyze) }
        expect(control.occurrences).not_to include(analyze_regex)

        control = ActiveRecord::QueryRecorder.new { described_class.new(my_model, connection: connection).sync_partitions(analyze: analyze) }
        expect(control.occurrences).not_to include(analyze_regex)

        travel_to((analyze_interval * 2).since) do
          control = ActiveRecord::QueryRecorder.new { described_class.new(my_model, connection: connection).sync_partitions(analyze: analyze) }
          expect(control.occurrences).not_to include(analyze_regex)
        end
      end
    end

    before do
      my_model.table_name = partitioned_table_name

      connection.execute(<<~SQL)
        CREATE TABLE #{analyze_table}(id serial) PARTITION BY LIST (id);
      SQL

      connection.execute(<<~SQL) if create_partition
        CREATE TABLE IF NOT EXISTS #{analyze_partition} PARTITION OF #{analyze_table} FOR VALUES IN (1);
      SQL

      allow(connection).to receive(:select_value).and_return(nil, Time.current, Time.current)
    end

    it_behaves_like 'run only once analyze within interval'

    context 'when analyze is false' do
      let(:analyze) { false }

      it_behaves_like 'not to run the analyze at all'
    end

    context 'when model does not set analyze_interval' do
      let(:my_model) do
        Class.new(ApplicationRecord) do
          include PartitionedTable

          partitioned_by :partition_id,
            strategy: :ci_sliding_list,
            next_partition_if: proc { false },
            detach_partition_if: proc { false }
        end
      end

      it_behaves_like 'not to run the analyze at all'
    end

    context 'when no partition is created' do
      let(:create_partition) { false }

      it_behaves_like 'run only once analyze within interval'
    end
  end

  describe 'strategies that support analyze_interval' do
    [
      ::Gitlab::Database::Partitioning::Time::MonthlyStrategy,
      ::Gitlab::Database::Partitioning::SlidingListStrategy,
      ::Gitlab::Database::Partitioning::CiSlidingListStrategy
    ].each do |klass|
      specify "#{klass} supports analyze_interval" do
        expect(klass).to be_method_defined(:analyze_interval)
      end
    end
  end

  context 'creating and then detaching partitions for a table' do
    let(:connection) { ActiveRecord::Base.connection }
    let(:my_model) do
      Class.new(ApplicationRecord) do
        include PartitionedTable

        partitioned_by :created_at, strategy: :monthly, retain_for: 1.month
      end
    end

    before do
      my_model.table_name = partitioned_table_name

      connection.execute(<<~SQL)
        CREATE TABLE #{partitioned_table_name}
        (id serial not null, created_at timestamptz not null, primary key (id, created_at))
        PARTITION BY RANGE (created_at);
      SQL
    end

    def num_partitions(model)
      find_partitions(model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA).size
    end

    it 'creates partitions for the future then drops the oldest one after a month' do
      # 1 month for the current month, 1 month for the old month that we're retaining data for, headroom
      expected_num_partitions = (Gitlab::Database::Partitioning::Time::MonthlyStrategy::HEADROOM + 2.months) / 1.month
      expect { described_class.new(my_model).sync_partitions }.to change { num_partitions(my_model) }.from(0).to(expected_num_partitions)

      travel 1.month

      expect { described_class.new(my_model).sync_partitions }.to change { has_partition(my_model, 2.months.ago.beginning_of_month) }.from(true).to(false).and(change { num_partitions(my_model) }.by(0))
    end
  end

  def has_partition(model, month)
    Gitlab::Database::PostgresPartition.for_parent_table(model.table_name).any? do |partition|
      Gitlab::Database::Partitioning::TimePartition.from_sql(
        model.table_name,
        partition.name,
        partition.condition
      ).from == month
    end
  end

  def create_partitioned_table(connection, table)
    connection.execute(<<~SQL)
      CREATE TABLE #{table}
      (id serial not null, created_at timestamptz not null, primary key (id, created_at))
      PARTITION BY RANGE (created_at);
    SQL
  end

  # Needed by track_record_deletions
  def execute(sql)
    connection.execute(sql)
  end
end
