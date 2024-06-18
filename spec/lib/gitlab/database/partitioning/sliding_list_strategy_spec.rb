# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::SlidingListStrategy, feature_category: :database do
  include Gitlab::Database::DynamicModelHelpers

  let(:connection) { ActiveRecord::Base.connection }
  let(:table_name) { '_test_partitioned_test' }
  let(:model) do
    define_batchable_model(table_name, connection: connection).tap { |m| m.ignored_columns = %w[partition] }
  end

  let(:next_partition_if) { double('next_partition_if') }
  let(:detach_partition_if) { double('detach_partition_if') }

  after do
    model.reset_column_information
  end

  subject(:strategy) do
    described_class.new(
      model,
      :partition,
      next_partition_if: next_partition_if,
      detach_partition_if: detach_partition_if
    )
  end

  before do
    connection.execute(<<~SQL)
      create table #{table_name}
        (
          id serial not null,
          partition bigint not null default 2,
          created_at timestamptz not null,
          primary key (id, partition)
        )
        partition by list(partition);

      create table #{table_name}_1
      partition of #{table_name} for values in (1);

      create table #{table_name}_2
      partition of #{table_name} for values in (2);
    SQL
  end

  describe '#current_partitions' do
    it 'detects both partitions' do
      expect(strategy.current_partitions).to eq(
        [
          Gitlab::Database::Partitioning::SingleNumericListPartition.new(
            table_name, 1, partition_name: '_test_partitioned_test_1'
          ),
          Gitlab::Database::Partitioning::SingleNumericListPartition.new(
            table_name, 2, partition_name: '_test_partitioned_test_2'
          )
        ])
    end
  end

  describe '#validate_and_fix' do
    it 'does not call change_column_default if the partitioning in a valid state' do
      expect(strategy.model.connection).not_to receive(:change_column_default)

      strategy.validate_and_fix
    end

    it 'calls change_column_default on partition_key with the most default partition number' do
      connection.change_column_default(model.table_name, strategy.partitioning_key, 1)

      expect(Gitlab::AppLogger).to receive(:warn).with(
        message: 'Fixed default value of sliding_list_strategy partitioning_key',
        connection_name: 'main',
        old_value: 1,
        new_value: 2,
        table_name: table_name,
        column: strategy.partitioning_key
      )

      expect(strategy.model.connection).to receive(:change_column_default).with(
        model.table_name, strategy.partitioning_key, 2
      ).and_call_original

      strategy.validate_and_fix
    end

    it 'does not change the default column if it has been changed in the meanwhile by another process' do
      expect(strategy).to receive(:current_default_value).and_return(1, 2)

      expect(strategy.model.connection).not_to receive(:change_column_default)

      expect(Gitlab::AppLogger).to receive(:warn).with(
        message: 'Table partitions or partition key default value have been changed by another process',
        table_name: table_name,
        default_value: 2
      )

      strategy.validate_and_fix
    end

    context 'when the shared connection is for the wrong database' do
      it 'does not attempt to fix connections' do
        skip_if_shared_database(:ci)
        expect(strategy.model.connection).not_to receive(:change_column_default)

        Ci::ApplicationRecord.connection.execute(<<~SQL)
          create table #{table_name}
          (
              id serial not null,
              partition bigint not null default 1,
              created_at timestamptz not null,
              primary key (id, partition)
          )
          partition by list(partition);

          create table #{table_name}_1
          partition of #{table_name} for values in (1);
        SQL

        Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
          strategy.validate_and_fix
        end
      end
    end
  end

  describe '#active_partition' do
    it 'is the partition with the largest value' do
      expect(strategy.active_partition.value).to eq(2)
    end
  end

  describe '#missing_partitions' do
    context 'when next_partition_if returns true' do
      let(:next_partition_if) { proc { true } }

      it 'is a partition definition for the next partition in the series' do
        extra = strategy.missing_partitions

        expect(extra.length).to eq(1)
        expect(extra.first.value).to eq(3)
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
        connection.execute("drop table #{table_name}_1; drop table #{table_name}_2;")

        missing_partitions = strategy.missing_partitions

        expect(missing_partitions.size).to eq(1)
        missing_partition = missing_partitions.first

        expect(missing_partition.value).to eq(1)
      end
    end
  end

  describe '#extra_partitions' do
    before do
      (3..10).each do |i|
        connection.execute("CREATE TABLE #{table_name}_#{i} PARTITION OF #{table_name} FOR VALUES IN (#{i})")
      end
    end

    context 'when some partitions are true for detach_partition_if' do
      let(:detach_partition_if) { ->(p) { p.value != 5 } }

      it 'is the leading set of partitions before that value' do
        # should not contain partition 2 since it's the default value for the partition column
        expect(strategy.extra_partitions.map(&:value)).to contain_exactly(1, 3, 4)
      end
    end

    context 'when all partitions are true for detach_partition_if' do
      let(:detach_partition_if) { proc { true } }

      it 'is all but the most recent partition', :aggregate_failures do
        expect(strategy.extra_partitions.map(&:value)).to contain_exactly(1, 3, 4, 5, 6, 7, 8, 9)

        expect(strategy.current_partitions.map(&:value).max).to eq(10)
      end
    end
  end

  describe '#initial_partition' do
    it 'starts with the value 1', :aggregate_failures do
      initial_partition = strategy.initial_partition
      expect(initial_partition.value).to eq(1)
      expect(initial_partition.table).to eq(strategy.table_name)
      expect(initial_partition.partition_name).to eq("#{strategy.table_name}_1")
    end
  end

  describe '#next_partition' do
    it 'is one after the active partition', :aggregate_failures do
      expect(strategy).to receive(:active_partition).and_return(double(value: 5))
      next_partition = strategy.next_partition

      expect(next_partition.value).to eq(6)
      expect(next_partition.table).to eq(strategy.table_name)
      expect(next_partition.partition_name).to eq("#{strategy.table_name}_6")
    end
  end

  describe '#ensure_partitioning_column_ignored!' do
    it 'raises when the column is not ignored' do
      expect do
        Class.new(ApplicationRecord) do
          include PartitionedTable

          partitioned_by :partition,
            strategy: :sliding_list,
            next_partition_if: proc { false },
            detach_partition_if: proc { false }
        end
      end.to raise_error(/ignored_columns/)
    end

    it 'does not raise when the column is ignored' do
      expect do
        Class.new(ApplicationRecord) do
          include PartitionedTable

          self.ignored_columns = [:partition]

          partitioned_by :partition,
            strategy: :sliding_list,
            next_partition_if: proc { false },
            detach_partition_if: proc { false }
        end
      end.not_to raise_error
    end
  end

  context 'redirecting inserts as the active partition changes' do
    let(:model) do
      Class.new(ApplicationRecord) do
        include PartitionedTable

        self.table_name = '_test_partitioned_test'
        self.primary_key = :id

        self.ignored_columns = %w[partition]

        # method().call cannot be detected by rspec, so we add a layer of indirection here
        def self.next_partition_if_wrapper(...)
          next_partition?(...)
        end

        def self.detach_partition_if_wrapper(...)
          detach_partition?(...)
        end
        partitioned_by :partition,
          strategy: :sliding_list,
          next_partition_if: method(:next_partition_if_wrapper),
          detach_partition_if: method(:detach_partition_if_wrapper)

        def self.next_partition?(current_partition); end

        def self.detach_partition?(partition); end
      end
    end

    it 'redirects to the new partition', :aggregate_failures do
      partition_2_model = model.create! # Goes in partition 2

      allow(model).to receive(:next_partition?) do
        model.partitioning_strategy.active_partition.value < 3
      end

      allow(model).to receive(:detach_partition?).and_return(false)

      Gitlab::Database::Partitioning::PartitionManager.new(model).sync_partitions

      partition_3_model = model.create!

      # Rails doesn't pick up on database default changes, so we need to reload
      # We also want to grab the partition column to verify what it was set to.
      # In normal operation we make rails ignore it so that we can use a changing default
      # So we force select * to load it
      all_columns = model.select(model.arel_table[Arel.star])
      partition_2_model = all_columns.find(partition_2_model.id)
      partition_3_model = all_columns.find(partition_3_model.id)

      expect(partition_2_model.partition).to eq(2)
      expect(partition_3_model.partition).to eq(3)
    end
  end

  describe '#after_adding_partitions' do
    context 'when the shared connection is for the same database' do
      it 'changes column default' do
        expect(strategy.model.connection)
          .to receive(:change_column_default)
          .and_call_original

        expect(Gitlab::AppLogger).not_to receive(:warn)

        Gitlab::Database::SharedModel.using_connection(ApplicationRecord.connection) do
          strategy.after_adding_partitions
        end
      end
    end

    context 'when the shared connection is for the wrong database' do
      it 'does not attempt to change column default' do
        skip_if_shared_database(:ci)
        expect(strategy.model.connection).not_to receive(:change_column_default)

        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: 'Skipping changing column default because connections mismatch',
          model_connection_name: 'main',
          shared_connection_name: 'ci',
          table_name: table_name,
          event: :partition_manager_after_adding_partitions_connection_mismatch
        )

        Gitlab::Database::SharedModel.using_connection(Ci::ApplicationRecord.connection) do
          strategy.after_adding_partitions
        end
      end
    end
  end

  describe 'attributes' do
    let(:partitioning_key) { :partition }
    let(:next_partition_if) { -> { puts "next_partition_if" } }
    let(:detach_partition_if) { -> { puts "detach_partition_if" } }
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
end
