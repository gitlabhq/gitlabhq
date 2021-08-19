# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionManager do
  include Database::PartitioningHelpers
  include ExclusiveLeaseHelpers

  def has_partition(model, month)
    Gitlab::Database::PostgresPartition.for_parent_table(model.table_name).any? do |partition|
      Gitlab::Database::Partitioning::TimePartition.from_sql(model.table_name, partition.name, partition.condition).from == month
    end
  end

  describe '.register' do
    let(:model) { double(partitioning_strategy: nil) }

    it 'remembers registered models' do
      expect { described_class.register(model) }.to change { described_class.models }.to include(model)
    end
  end

  context 'creating partitions (mocked)' do
    subject(:sync_partitions) { described_class.new(models).sync_partitions }

    let(:models) { [model] }
    let(:model) { double(partitioning_strategy: partitioning_strategy, table_name: table) }
    let(:partitioning_strategy) { double(missing_partitions: partitions, extra_partitions: []) }
    let(:table) { "some_table" }

    before do
      allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_call_original
      allow(ActiveRecord::Base.connection).to receive(:table_exists?).with(table).and_return(true)
      allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original

      stub_exclusive_lease(described_class::MANAGEMENT_LEASE_KEY % table, timeout: described_class::LEASE_TIMEOUT)
    end

    let(:partitions) do
      [
        instance_double(Gitlab::Database::Partitioning::TimePartition, table: 'bar', partition_name: 'foo', to_sql: "SELECT 1"),
        instance_double(Gitlab::Database::Partitioning::TimePartition, table: 'bar', partition_name: 'foo2', to_sql: "SELECT 2")
      ]
    end

    it 'creates the partition' do
      expect(ActiveRecord::Base.connection).to receive(:execute).with(partitions.first.to_sql)
      expect(ActiveRecord::Base.connection).to receive(:execute).with(partitions.second.to_sql)

      sync_partitions
    end

    context 'error handling with 2 models' do
      let(:models) do
        [
          double(partitioning_strategy: strategy1, table_name: table),
          double(partitioning_strategy: strategy2, table_name: table)
        ]
      end

      let(:strategy1) { double('strategy1', missing_partitions: nil, extra_partitions: []) }
      let(:strategy2) { double('strategy2', missing_partitions: partitions, extra_partitions: []) }

      it 'still creates partitions for the second table' do
        expect(strategy1).to receive(:missing_partitions).and_raise('this should never happen (tm)')
        expect(ActiveRecord::Base.connection).to receive(:execute).with(partitions.first.to_sql)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(partitions.second.to_sql)

        sync_partitions
      end
    end
  end

  context 'creating partitions' do
    subject(:sync_partitions) { described_class.new([my_model]).sync_partitions }

    let(:connection) { ActiveRecord::Base.connection }
    let(:my_model) do
      Class.new(ApplicationRecord) do
        include PartitionedTable

        self.table_name = 'my_model_example_table'

        partitioned_by :created_at, strategy: :monthly
      end
    end

    before do
      connection.execute(<<~SQL)
        CREATE TABLE my_model_example_table
        (id serial not null, created_at timestamptz not null, primary key (id, created_at))
        PARTITION BY RANGE (created_at);
      SQL
    end

    it 'creates partitions' do
      expect { sync_partitions }.to change { find_partitions(my_model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA).size }.from(0)
    end
  end

  context 'detaching partitions (mocked)' do
    subject(:sync_partitions) { manager.sync_partitions }

    let(:manager) { described_class.new(models) }
    let(:models) { [model] }
    let(:model) { double(partitioning_strategy: partitioning_strategy, table_name: table)}
    let(:partitioning_strategy) { double(extra_partitions: extra_partitions, missing_partitions: []) }
    let(:table) { "foo" }

    before do
      allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_call_original
      allow(ActiveRecord::Base.connection).to receive(:table_exists?).with(table).and_return(true)

      stub_exclusive_lease(described_class::MANAGEMENT_LEASE_KEY % table, timeout: described_class::LEASE_TIMEOUT)
    end

    let(:extra_partitions) do
      [
        instance_double(Gitlab::Database::Partitioning::TimePartition, table: table, partition_name: 'foo1', to_detach_sql: 'SELECT 1'),
        instance_double(Gitlab::Database::Partitioning::TimePartition, table: table, partition_name: 'foo2', to_detach_sql: 'SELECT 2')
      ]
    end

    context 'with the partition_pruning feature flag enabled' do
      before do
        stub_feature_flags(partition_pruning: true)
      end

      it 'detaches each extra partition' do
        extra_partitions.each { |p| expect(manager).to receive(:detach_one_partition).with(p) }

        sync_partitions
      end

      context 'error handling' do
        let(:models) do
          [
            double(partitioning_strategy: error_strategy, table_name: table),
            model
          ]
        end

        let(:error_strategy) { double(extra_partitions: nil, missing_partitions: []) }

        it 'still drops partitions for the other model' do
          expect(error_strategy).to receive(:extra_partitions).and_raise('injected error!')
          extra_partitions.each { |p| expect(manager).to receive(:detach_one_partition).with(p) }

          sync_partitions
        end
      end
    end

    context 'with the partition_pruning feature flag disabled' do
      before do
        stub_feature_flags(partition_pruning: false)
      end

      it 'returns immediately' do
        expect(manager).not_to receive(:detach)

        sync_partitions
      end
    end
  end

  describe '#detach_partitions' do
    around do |ex|
      travel_to(Date.parse('2021-06-23')) do
        ex.run
      end
    end

    subject { described_class.new([my_model]).sync_partitions }

    let(:connection) { ActiveRecord::Base.connection }
    let(:my_model) do
      Class.new(ApplicationRecord) do
        include PartitionedTable

        self.table_name = 'my_model_example_table'

        partitioned_by :created_at, strategy: :monthly, retain_for: 1.month
      end
    end

    before do
      connection.execute(<<~SQL)
        CREATE TABLE my_model_example_table
        (id serial not null, created_at timestamptz not null, primary key (id, created_at))
        PARTITION BY RANGE (created_at);

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.my_model_example_table_202104
        PARTITION OF my_model_example_table
        FOR VALUES FROM ('2021-04-01') TO ('2021-05-01');

        CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.my_model_example_table_202105
        PARTITION OF my_model_example_table
        FOR VALUES FROM ('2021-05-01') TO ('2021-06-01');
      SQL

      # Also create all future partitions so that the sync is only trying to detach old partitions
      my_model.partitioning_strategy.missing_partitions.each do |p|
        connection.execute p.to_sql
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
      expect { subject }.to change { find_partitions(my_model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA).size }.from(9).to(8)
    end

    it 'detaches the old partition' do
      expect { subject }.to change { has_partition(my_model, 2.months.ago.beginning_of_month) }.from(true).to(false)
    end

    it 'deletes zero tables' do
      expect { subject }.not_to change { num_tables }
    end

    it 'creates the appropriate PendingPartitionDrop entry' do
      subject

      pending_drop = Postgresql::DetachedPartition.find_by!(table_name: 'my_model_example_table_202104')
      expect(pending_drop.drop_after).to eq(Time.current + described_class::RETAIN_DETACHED_PARTITIONS_FOR)
    end

    # Postgres 11 does not support foreign keys to partitioned tables
    if Gitlab::Database.main.version.to_f >= 12
      context 'when the model is the target of a foreign key' do
        before do
          connection.execute(<<~SQL)
        create unique index idx_for_fk ON my_model_example_table(created_at);

        create table referencing_table (
          id bigserial primary key not null,
          referencing_created_at timestamptz references my_model_example_table(created_at)
        );
          SQL
        end

        it 'does not detach partitions with a referenced foreign key' do
          expect { subject }.not_to change { find_partitions(my_model.table_name).size }
        end
      end
    end
  end

  context 'creating and then detaching partitions for a table' do
    let(:connection) { ActiveRecord::Base.connection }
    let(:my_model) do
      Class.new(ApplicationRecord) do
        include PartitionedTable

        self.table_name = 'my_model_example_table'

        partitioned_by :created_at, strategy: :monthly, retain_for: 1.month
      end
    end

    before do
      connection.execute(<<~SQL)
        CREATE TABLE my_model_example_table
        (id serial not null, created_at timestamptz not null, primary key (id, created_at))
        PARTITION BY RANGE (created_at);
      SQL
    end

    def num_partitions(model)
      find_partitions(model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA).size
    end

    it 'creates partitions for the future then drops the oldest one after a month' do
      # 1 month for the current month, 1 month for the old month that we're retaining data for, headroom
      expected_num_partitions = (Gitlab::Database::Partitioning::MonthlyStrategy::HEADROOM + 2.months) / 1.month
      expect { described_class.new([my_model]).sync_partitions }.to change { num_partitions(my_model) }.from(0).to(expected_num_partitions)

      travel 1.month

      expect { described_class.new([my_model]).sync_partitions }.to change { has_partition(my_model, 2.months.ago.beginning_of_month) }.from(true).to(false).and(change { num_partitions(my_model) }.by(0))
    end
  end
end
