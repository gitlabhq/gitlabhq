# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresPartitionedTable, type: :model do
  let_it_be(:foo_range_table_name) { '_test_gitlab_main_foo_range' }
  let_it_be(:foo_list_table_name) { '_test_gitlab_main_foo_list' }
  let_it_be(:foo_hash_table_name) { '_test_gitlab_main_foo_hash' }

  let_it_be(:schema) { 'public' }
  let_it_be(:name) { foo_range_table_name }
  let_it_be(:identifier) { "#{schema}.#{name}" }

  before_all do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE #{schema}.#{foo_range_table_name} (
        id serial NOT NULL,
        created_at timestamptz NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE(created_at);

      CREATE TABLE #{schema}.#{foo_list_table_name} (
        id serial NOT NULL,
        row_type text NOT NULL,
        PRIMARY KEY (id, row_type)
      ) PARTITION BY LIST(row_type);

      CREATE TABLE #{schema}.#{foo_hash_table_name} (
        id serial NOT NULL,
        row_value int NOT NULL,
        PRIMARY KEY (id, row_value)
      ) PARTITION BY HASH (row_value);
    SQL
  end

  def find(identifier)
    described_class.by_identifier(identifier)
  end

  describe 'associations' do
    it { is_expected.to have_many(:postgres_partitions).with_primary_key('identifier').with_foreign_key('parent_identifier') }
  end

  it_behaves_like 'a postgres model'

  describe '.find_by_name_in_current_schema' do
    it 'finds the partitioned tables in the current schema by name', :aggregate_failures do
      partitioned_table = described_class.find_by_name_in_current_schema(name)

      expect(partitioned_table).not_to be_nil
      expect(partitioned_table.identifier).to eq(identifier)
    end

    it 'does not find partitioned tables in a different schema' do
      ActiveRecord::Base.connection.execute(<<~SQL)
        ALTER TABLE #{identifier} SET SCHEMA gitlab_partitions_dynamic
      SQL

      expect(described_class.find_by_name_in_current_schema(name)).to be_nil
    end
  end

  describe '.each_partition' do
    context 'without partitions' do
      it 'does not yield control' do
        expect { |b| described_class.each_partition(name, &b) }.not_to yield_control
      end
    end

    context 'with partitions' do
      let(:partition_schema) { 'gitlab_partitions_dynamic' }
      let(:partition1_name) { "#{partition_schema}.#{name}_202001" }
      let(:partition2_name) { "#{partition_schema}.#{name}_202002" }

      before do
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE #{partition1_name} PARTITION OF #{identifier}
          FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

          CREATE TABLE #{partition2_name} PARTITION OF #{identifier}
          FOR VALUES FROM ('2020-02-01') TO ('2020-03-01');
        SQL
      end

      it 'yields control with partition as argument' do
        args = Gitlab::Database::PostgresPartition
          .where(identifier: [partition1_name, partition2_name])
          .order(:name).to_a

        expect { |b| described_class.each_partition(name, &b) }.to yield_successive_args(*args)
      end
    end
  end

  describe '#dynamic?' do
    it 'returns true for tables partitioned by range' do
      expect(find("#{schema}.#{foo_range_table_name}")).to be_dynamic
    end

    it 'returns true for tables partitioned by list' do
      expect(find("#{schema}.#{foo_list_table_name}")).to be_dynamic
    end

    it 'returns false for tables partitioned by hash' do
      expect(find("#{schema}.#{foo_hash_table_name}")).not_to be_dynamic
    end
  end

  describe '#static?' do
    it 'returns false for tables partitioned by range' do
      expect(find("#{schema}.#{foo_range_table_name}")).not_to be_static
    end

    it 'returns false for tables partitioned by list' do
      expect(find("#{schema}.#{foo_list_table_name}")).not_to be_static
    end

    it 'returns true for tables partitioned by hash' do
      expect(find("#{schema}.#{foo_hash_table_name}")).to be_static
    end
  end

  describe '#strategy' do
    it 'returns the partitioning strategy' do
      expect(find(identifier).strategy).to eq('range')
    end
  end

  describe '#key_columns' do
    it 'returns the partitioning key columns' do
      expect(find(identifier).key_columns).to match_array(['created_at'])
    end
  end
end
