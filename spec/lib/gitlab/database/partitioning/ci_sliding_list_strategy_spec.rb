# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::CiSlidingListStrategy, feature_category: :database do
  let(:connection) { ActiveRecord::Base.connection }
  let(:table_name) { :_test_gitlab_ci_partitioned_test }
  let(:model) { class_double(ApplicationRecord, table_name: table_name, connection: connection) }
  let(:next_partition_if) { ->(_) { false } }
  let(:detach_partition_if) { ->(_) { false } }

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
          Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
            table_name, 100, partition_name: "#{table_name}_100"
          ),
          Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
            table_name, 101, partition_name: "#{table_name}_101"
          )
        ])
    end

    context 'with multiple values' do
      before do
        connection.execute(<<~SQL)
          create table #{table_name}_test
          partition of #{table_name} for values in (102, 103, 104);
        SQL
      end

      it 'detects all partitions' do
        expect(strategy.current_partitions).to eq(
          [
            Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
              table_name, 100, partition_name: "#{table_name}_100"
            ),
            Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
              table_name, 101, partition_name: "#{table_name}_101"
            ),
            Gitlab::Database::Partitioning::MultipleNumericListPartition.new(
              table_name, [102, 103, 104], partition_name: "#{table_name}_test"
            )
          ])
      end
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
      expect(strategy.active_partition.values).to eq([101])
    end

    context 'when there are no partitions' do
      before do
        drop_partitions
      end

      it 'is the initial partition' do
        expect(strategy.active_partition.values).to eq([100])
      end
    end
  end

  describe '#missing_partitions' do
    context 'when next_partition_if returns true' do
      let(:next_partition_if) { proc { |partition| partition.values.max < 102 } }

      it 'is a partition definition for the next partition in the series' do
        extra = strategy.missing_partitions

        expect(extra.length).to eq(1)
        expect(extra.first.values).to eq([102])
      end

      context 'when there are no partitions for the table' do
        it 'returns partitions for value 100 and 101' do
          drop_partitions

          missing_partitions = strategy.missing_partitions

          expect(missing_partitions.size).to eq(3)
          expect(missing_partitions.map(&:values)).to match_array([[100], [101], [102]])
        end
      end
    end

    context 'when next_partition_if returns false' do
      let(:next_partition_if) { proc { false } }

      it 'is empty' do
        expect(strategy.missing_partitions).to be_empty
      end
    end

    context 'when there are no partitions for the table' do
      it 'returns a partition for value 100' do
        drop_partitions

        missing_partitions = strategy.missing_partitions

        expect(missing_partitions.size).to eq(1)
        missing_partition = missing_partitions.first

        expect(missing_partition.values).to eq([100])
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
      expect(initial_partition.values).to eq([100])
      expect(initial_partition.table).to eq(strategy.table_name)
      expect(initial_partition.partition_name).to eq("#{strategy.table_name}_100")
    end

    context 'with routing tables' do
      let(:table_name) { :p_test_gitlab_ci_partitioned_test }

      it 'removes the prefix', :aggregate_failures do
        initial_partition = strategy.initial_partition

        expect(initial_partition.values).to eq([100])
        expect(initial_partition.table).to eq(strategy.table_name)
        expect(initial_partition.partition_name).to eq('test_gitlab_ci_partitioned_test_100')
      end
    end
  end

  describe '#next_partition' do
    before do
      allow(strategy)
        .to receive(:active_partition)
        .and_return(instance_double(Gitlab::Database::Partitioning::MultipleNumericListPartition, values: [105]))
    end

    it 'is one after the active partition', :aggregate_failures do
      next_partition = strategy.next_partition

      expect(next_partition.values).to eq([106])
      expect(next_partition.table).to eq(strategy.table_name)
      expect(next_partition.partition_name).to eq("#{strategy.table_name}_106")
    end

    context 'with routing tables' do
      let(:table_name) { :p_test_gitlab_ci_partitioned_test }

      it 'removes the prefix', :aggregate_failures do
        next_partition = strategy.next_partition

        expect(next_partition.values).to eq([106])
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

  describe 'attributes' do
    let(:partitioning_key) { :partition }
    let(:next_partition_if) { -> { true } }
    let(:detach_partition_if) { -> { false } }
    let(:analyze_interval) { 1.week }

    subject(:strategy) do
      described_class.new(
        model, partitioning_key,
        next_partition_if: next_partition_if,
        detach_partition_if: detach_partition_if,
        analyze_interval: analyze_interval
      )
    end

    specify do
      expect(strategy).to have_attributes({
        model: model,
        partitioning_key: partitioning_key,
        next_partition_if: next_partition_if,
        detach_partition_if: detach_partition_if,
        analyze_interval: analyze_interval
      })
    end
  end

  def drop_partitions
    connection.execute("drop table #{table_name}_100; drop table #{table_name}_101;")
  end
end
