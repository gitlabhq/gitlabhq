# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::CiSlidingListStrategy, feature_category: :database do
  let(:connection) { ActiveRecord::Base.connection }
  let(:table_name) { :_test_gitlab_ci_partitioned_test }
  let(:model) { class_double(ApplicationRecord, table_name: table_name, connection: connection) }
  let(:next_partition_if) { nil }
  let(:detach_partition_if) { nil }

  subject(:strategy) do
    described_class.new(model, :partition,
      next_partition_if: next_partition_if,
      detach_partition_if: detach_partition_if)
  end

  before do
    next if table_name.to_s.starts_with?('p_')

    connection.execute(<<~SQL)
      create table #{table_name}
        (
          id serial not null,
          partition_id bigint not null,
          created_at timestamptz not null,
          primary key (id, partition_id)
        )
        partition by list(partition_id);

      create table #{table_name}_100
      partition of #{table_name} for values in (100);

      create table #{table_name}_101
      partition of #{table_name} for values in (101);
    SQL
  end

  describe '#current_partitions' do
    it 'detects both partitions' do
      expect(strategy.current_partitions).to eq(
        [
          Gitlab::Database::Partitioning::SingleNumericListPartition.new(
            table_name, 100, partition_name: "#{table_name}_100"
          ),
          Gitlab::Database::Partitioning::SingleNumericListPartition.new(
            table_name, 101, partition_name: "#{table_name}_101"
          )
        ])
    end
  end

  describe '#validate_and_fix' do
    it 'does not call change_column_default' do
      expect(strategy.model.connection).not_to receive(:change_column_default)

      strategy.validate_and_fix
    end
  end

  describe '#active_partition' do
    it 'is the partition with the largest value' do
      expect(strategy.active_partition.value).to eq(101)
    end
  end

  describe '#missing_partitions' do
    context 'when next_partition_if returns true' do
      let(:next_partition_if) { proc { true } }

      it 'is a partition definition for the next partition in the series' do
        extra = strategy.missing_partitions

        expect(extra.length).to eq(1)
        expect(extra.first.value).to eq(102)
      end
    end

    context 'when next_partition_if returns false' do
      let(:next_partition_if) { proc { false } }

      it 'is empty' do
        expect(strategy.missing_partitions).to be_empty
      end
    end

    context 'when there are no partitions for the table' do
      it 'returns a partition for value 1' do
        connection.execute("drop table #{table_name}_100; drop table #{table_name}_101;")

        missing_partitions = strategy.missing_partitions

        expect(missing_partitions.size).to eq(1)
        missing_partition = missing_partitions.first

        expect(missing_partition.value).to eq(100)
      end
    end
  end

  describe '#extra_partitions' do
    context 'when all partitions are true for detach_partition_if' do
      let(:detach_partition_if) { ->(_p) { true } }

      it { expect(strategy.extra_partitions).to be_empty }
    end

    context 'when all partitions are false for detach_partition_if' do
      let(:detach_partition_if) { proc { false } }

      it { expect(strategy.extra_partitions).to be_empty }
    end
  end

  describe '#initial_partition' do
    it 'starts with the value 100', :aggregate_failures do
      initial_partition = strategy.initial_partition
      expect(initial_partition.value).to eq(100)
      expect(initial_partition.table).to eq(strategy.table_name)
      expect(initial_partition.partition_name).to eq("#{strategy.table_name}_100")
    end

    context 'with routing tables' do
      let(:table_name) { :p_test_gitlab_ci_partitioned_test }

      it 'removes the prefix', :aggregate_failures do
        initial_partition = strategy.initial_partition

        expect(initial_partition.value).to eq(100)
        expect(initial_partition.table).to eq(strategy.table_name)
        expect(initial_partition.partition_name).to eq('test_gitlab_ci_partitioned_test_100')
      end
    end
  end

  describe '#next_partition' do
    before do
      allow(strategy)
        .to receive(:active_partition)
        .and_return(instance_double(Gitlab::Database::Partitioning::SingleNumericListPartition, value: 105))
    end

    it 'is one after the active partition', :aggregate_failures do
      next_partition = strategy.next_partition

      expect(next_partition.value).to eq(106)
      expect(next_partition.table).to eq(strategy.table_name)
      expect(next_partition.partition_name).to eq("#{strategy.table_name}_106")
    end

    context 'with routing tables' do
      let(:table_name) { :p_test_gitlab_ci_partitioned_test }

      it 'removes the prefix', :aggregate_failures do
        next_partition = strategy.next_partition

        expect(next_partition.value).to eq(106)
        expect(next_partition.table).to eq(strategy.table_name)
        expect(next_partition.partition_name).to eq('test_gitlab_ci_partitioned_test_106')
      end
    end
  end

  describe '#ensure_partitioning_column_ignored_or_readonly!' do
    it 'does not raise when the column is not ignored' do
      expect do
        Class.new(ApplicationRecord) do
          include PartitionedTable

          partitioned_by :partition_id,
            strategy: :ci_sliding_list,
            next_partition_if: proc { false },
            detach_partition_if: proc { false }
        end
      end.not_to raise_error
    end
  end
end
