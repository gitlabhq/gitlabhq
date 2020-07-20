# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionCreator do
  include PartitioningHelpers
  include ExclusiveLeaseHelpers

  describe '.register' do
    let(:model) { double(partitioning_strategy: nil) }

    it 'remembers registered models' do
      expect { described_class.register(model) }.to change { described_class.models }.to include(model)
    end
  end

  describe '#create_partitions (mocked)' do
    subject { described_class.new(models).create_partitions }

    let(:models) { [model] }
    let(:model) { double(partitioning_strategy: partitioning_strategy, table_name: table) }
    let(:partitioning_strategy) { double(missing_partitions: partitions) }
    let(:table) { "some_table" }

    before do
      allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_call_original
      allow(ActiveRecord::Base.connection).to receive(:table_exists?).with(table).and_return(true)
      allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original

      stub_exclusive_lease(described_class::LEASE_KEY % table, timeout: described_class::LEASE_TIMEOUT)
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

      subject
    end

    context 'error handling with 2 models' do
      let(:models) do
        [
          double(partitioning_strategy: strategy1, table_name: table),
          double(partitioning_strategy: strategy2, table_name: table)
        ]
      end

      let(:strategy1) { double('strategy1', missing_partitions: nil) }
      let(:strategy2) { double('strategy2', missing_partitions: partitions) }

      it 'still creates partitions for the second table' do
        expect(strategy1).to receive(:missing_partitions).and_raise('this should never happen (tm)')
        expect(ActiveRecord::Base.connection).to receive(:execute).with(partitions.first.to_sql)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(partitions.second.to_sql)

        subject
      end
    end
  end

  describe '#create_partitions' do
    subject { described_class.new([my_model]).create_partitions }

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
      expect { subject }.to change { find_partitions(my_model.table_name, schema: Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA).size }.from(0)

      subject
    end
  end
end
