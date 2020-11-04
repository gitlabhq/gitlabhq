# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresPartitionedTable, type: :model do
  let(:schema) { 'public' }
  let(:name) { 'foo_range' }
  let(:identifier) { "#{schema}.#{name}" }

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE #{identifier} (
        id serial NOT NULL,
        created_at timestamptz NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE(created_at);

      CREATE TABLE public.foo_list (
        id serial NOT NULL,
        row_type text NOT NULL,
        PRIMARY KEY (id, row_type)
      ) PARTITION BY LIST(row_type);

      CREATE TABLE public.foo_hash (
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

  describe '#dynamic?' do
    it 'returns true for tables partitioned by range' do
      expect(find('public.foo_range')).to be_dynamic
    end

    it 'returns true for tables partitioned by list' do
      expect(find('public.foo_list')).to be_dynamic
    end

    it 'returns false for tables partitioned by hash' do
      expect(find('public.foo_hash')).not_to be_dynamic
    end
  end

  describe '#static?' do
    it 'returns false for tables partitioned by range' do
      expect(find('public.foo_range')).not_to be_static
    end

    it 'returns false for tables partitioned by list' do
      expect(find('public.foo_list')).not_to be_static
    end

    it 'returns true for tables partitioned by hash' do
      expect(find('public.foo_hash')).to be_static
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
