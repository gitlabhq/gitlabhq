# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionManager do
  include Database::PartitioningHelpers
  include Database::TableSchemaHelpers
  include ExclusiveLeaseHelpers

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
        instance_double(Gitlab::Database::Partitioning::TimePartition, table: table, partition_name: 'foo1'),
        instance_double(Gitlab::Database::Partitioning::TimePartition, table: table, partition_name: 'foo2')
      ]
    end

    context 'with the partition_pruning_dry_run feature flag enabled' do
      before do
        stub_feature_flags(partition_pruning_dry_run: true)
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

    context 'with the partition_pruning_dry_run feature flag disabled' do
      before do
        stub_feature_flags(partition_pruning_dry_run: false)
      end

      it 'returns immediately' do
        expect(manager).not_to receive(:detach)

        sync_partitions
      end
    end
  end
end
