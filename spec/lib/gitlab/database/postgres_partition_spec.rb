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
          .with_parent_tables(Ci::Partitionable.registered_models.map(&:table_name))
          .with_list_constraint(partition_id)
      end

      context 'when condition matches' do
        let(:partition_id) { '102' }
        let(:expected_size) { Ci::Partitionable.registered_models.size }

        it 'returns the partitions containing the match' do
          results = with_list_constraint

          expect(results.size).to eq(expected_size)
        end
      end

      context 'when condition does not match' do
        let(:partition_id) { non_existing_record_id }

        it 'returns an empty relation' do
          expect(with_list_constraint).to be_empty
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

  describe '.partition_exists?' do
    subject { described_class.partition_exists?(table_name) }

    context 'when the partition exists' do
      let(:table_name) { "ci_builds_metadata" }

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
      let(:table_name) { "ci_builds_metadata" }

      it { is_expected.to be_truthy }
    end

    context 'when the partition does not exist' do
      let(:table_name) { 'partition_does_not_exist' }

      it { is_expected.to be_falsey }
    end
  end
end
