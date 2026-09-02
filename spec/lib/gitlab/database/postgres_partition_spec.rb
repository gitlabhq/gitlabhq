# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresPartition, type: :model, feature_category: :database do
  let(:current_schema) { ActiveRecord::Base.connection.select_value("SELECT current_schema()") }
  let(:schema) { 'gitlab_partitions_dynamic' }
  let(:name) { '_test_partition_01' }
  let(:identifier) { "#{schema}.#{name}" }

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE public._test_partitioned_table (
        id serial NOT NULL,
        created_at timestamptz NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE(created_at);

      CREATE TABLE #{identifier} PARTITION OF public._test_partitioned_table
      FOR VALUES FROM ('2020-01-01') to ('2020-02-01');
    SQL
  end

  def find(identifier)
    described_class.by_identifier(identifier)
  end

  describe 'associations' do
    it { is_expected.to belong_to(:postgres_partitioned_table).with_primary_key('identifier').with_foreign_key('parent_identifier') }
  end

  it_behaves_like 'a postgres model'

  describe 'scopes' do
    describe '.with_parent_tables' do
      subject(:with_parent_tables) { described_class.with_parent_tables(parent_tables) }

      let(:parent_tables) { ['_test_partitioned_table'] }

      it 'returns all partitions with parent tables', :aggregate_failures do
        results = with_parent_tables

        expect(results.size).to eq(1)
        expect(results.first.identifier).to eq(identifier)
      end
    end

    describe '.with_list_constraint' do
      subject(:with_list_constraint) do
        described_class
          .with_parent_tables(parent_tables)
          .with_list_constraint(partition_id)
      end

      let(:parent_tables) { [parent_table] }
      let(:parent_table) { '_test_list_partitioned_table' }
      let(:partition_name) { '_test_list_partition_102' }
      let(:multi_partition_name) { '_test_list_partition_200_202' }

      shared_examples 'matching a list partition bound' do
        before do
          ActiveRecord::Base.connection.execute(<<~SQL)
            CREATE TABLE public.#{parent_table} (
              partition_id #{partition_key_type} NOT NULL,
              PRIMARY KEY (partition_id)
            ) PARTITION BY LIST (partition_id);

            CREATE TABLE #{schema}.#{partition_name}
              PARTITION OF public.#{parent_table} FOR VALUES IN (102);

            CREATE TABLE #{schema}.#{multi_partition_name}
              PARTITION OF public.#{parent_table} FOR VALUES IN (200, 201, 202);
          SQL
        end

        context 'when condition matches' do
          let(:partition_id) { '102' }

          it 'returns the partitions containing the match' do
            results = with_list_constraint

            expect(results.map(&:name)).to contain_exactly(partition_name)
          end
        end

        context 'when condition does not match' do
          where(:partition_id) { [non_existing_record_id, 10, 2, 1020] }

          with_them do
            it 'returns an empty relation' do
              expect(with_list_constraint).to be_empty
            end
          end
        end

        context 'when the bound covers several values' do
          it 'returns the partition for each value it covers', :aggregate_failures do
            [200, 201, 202].each do |value|
              results = described_class.with_parent_tables(parent_tables).with_list_constraint(value)

              expect(results.map(&:name)).to contain_exactly(multi_partition_name)
            end
          end

          context 'when the value falls outside the bound' do
            let(:partition_id) { 203 }

            it 'returns an empty relation' do
              expect(with_list_constraint).to be_empty
            end
          end
        end
      end

      context 'when the partition key is an integer' do
        let(:partition_key_type) { 'integer' }

        it_behaves_like 'matching a list partition bound'
      end

      context 'when the partition key is a smallint' do
        let(:partition_key_type) { 'smallint' }

        it_behaves_like 'matching a list partition bound'
      end

      context 'when the partition key is a bigint' do
        let(:partition_key_type) { 'bigint' }

        it_behaves_like 'matching a list partition bound'
      end

      context 'when the parent tables are registered with Ci::Partitionable' do
        let(:parent_tables) { Ci::Partitionable.registered_models.map(&:table_name) }
        let(:partition_id) { '102' }
        let(:expected_size) { Ci::Partitionable.registered_models.size }

        it 'returns the partitions containing the match' do
          results = with_list_constraint

          expect(results.size).to eq(expected_size)
        end
      end
    end

    describe '.above_threshold' do
      subject(:above_threshold) { described_class.above_threshold(threshold) }

      context 'when the partition size is above a given threshold' do
        let(:threshold) { 1.byte }

        it 'returns all partitions above the threshold' do
          expect(above_threshold.size).not_to be_zero
        end
      end

      context 'when the partition size is below a given threshold' do
        let(:threshold) { 100.megabytes }

        it 'returns an empty relation' do
          expect(above_threshold).to be_empty
        end
      end
    end
  end

  describe '.for_parent_table' do
    let(:second_name) { '_test_partition_02' }

    before do
      ActiveRecord::Base.connection.execute(<<~SQL)
        CREATE TABLE #{schema}.#{second_name} PARTITION OF public._test_partitioned_table
        FOR VALUES FROM ('2020-02-01') to ('2020-03-01');

        CREATE TABLE #{schema}._test_other_table (
          id serial NOT NULL,
          created_at timestamptz NOT NULL,
          PRIMARY KEY (id, created_at)
        ) PARTITION BY RANGE(created_at);

        CREATE TABLE #{schema}._test_other_partition_01 PARTITION OF #{schema}._test_other_table
        FOR VALUES FROM ('2020-01-01') to ('2020-02-01');
      SQL
    end

    it 'returns partitions for the parent table in the current schema' do
      partitions = described_class.for_parent_table('_test_partitioned_table')

      expect(partitions.count).to eq(2)
      expect(partitions.pluck(:name)).to eq([name, second_name])
    end

    it 'returns the partitions if the parent table schema is included in the table name' do
      partitions = described_class.for_parent_table("#{current_schema}._test_partitioned_table")

      expect(partitions.count).to eq(2)
      expect(partitions.pluck(:name)).to eq([name, second_name])
    end

    it 'does not return partitions for tables not in the current schema' do
      expect(described_class.for_parent_table('_test_other_table').count).to eq(0)
    end

    it 'does not return partitions for tables if the schema is not the current' do
      expect(described_class.for_parent_table('foo_bar._test_partitioned_table').count).to eq(0)
    end
  end

  describe '#parent_identifier' do
    it 'returns the parent table identifier' do
      expect(find(identifier).parent_identifier).to eq('public._test_partitioned_table')
    end
  end

  describe '#condition' do
    it 'returns the condition for the partitioned values' do
      expect(find(identifier).condition).to eq("FOR VALUES FROM ('2020-01-01 00:00:00+00') TO ('2020-02-01 00:00:00+00')")
    end
  end

  describe '#pending_detach' do
    it 'is false for an attached partition' do
      expect(find(identifier).pending_detach).to be(false)
    end

    context 'when a concurrent detach of the partition has not finalized' do
      before do
        # Mocks an interrupted DETACH...CONCURRENTLY
        ActiveRecord::Base.connection.execute(<<~SQL)
          UPDATE pg_inherits SET inhdetachpending = true
          WHERE inhrelid = '#{identifier}'::regclass
        SQL
      end

      it 'is true, and the partition still reads as attached' do
        expect(find(identifier).pending_detach).to be(true)
        expect(described_class.for_identifier(identifier)).not_to be_empty
      end
    end
  end

  describe '.partition_exists?' do
    subject { described_class.partition_exists?(table_name) }

    context 'when the partition exists' do
      let(:table_name) { "_test_partition_02" }

      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{table_name} PARTITION OF public._test_partitioned_table
          FOR VALUES FROM ('2020-02-01') to ('2020-03-01');
        SQL
      end

      it { is_expected.to be_truthy }
    end

    context 'when the partition does not exist' do
      let(:table_name) { 'partition_does_not_exist' }

      it { is_expected.to be_falsey }
    end
  end

  describe '.legacy_partition_exists?' do
    subject { described_class.legacy_partition_exists?(table_name) }

    context 'when the partition exists' do
      let(:table_name) { "_test_partition_02" }

      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{table_name} PARTITION OF public._test_partitioned_table
          FOR VALUES FROM ('2020-02-01') to ('2020-03-01');
        SQL
      end

      it { is_expected.to be_truthy }
    end

    context 'when the partition does not exist' do
      let(:table_name) { 'partition_does_not_exist' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#list_partition_ids' do
    it 'extracts partitions ids for single value' do
      partition = described_class.new(condition: "FOR VALUES IN ('100')")

      expect(partition.list_partition_ids).to eq([100])
    end

    it 'extracts partitions ids for multiple values' do
      partition = described_class.new(condition: "FOR VALUES IN ('100', '101', '102')")

      expect(partition.list_partition_ids).to match_array([100, 101, 102])
    end

    it 'returns empty array when condition is blank' do
      partition = described_class.new(condition: nil)

      expect(partition.list_partition_ids).to eq([])
    end
  end
end
