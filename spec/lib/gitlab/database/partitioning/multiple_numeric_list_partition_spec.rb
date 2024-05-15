# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::MultipleNumericListPartition, feature_category: :database do
  describe '.from_sql' do
    subject(:parsed_partition) { described_class.from_sql(table, partition_name, definition, schema: nil) }

    let(:table) { 'partitioned_table' }

    context 'with single partition values' do
      let(:partition_value) { 10 }
      let(:partition_name) { "partitioned_table_#{partition_value}" }
      let(:definition) { "FOR VALUES IN ('#{partition_value}')" }

      it 'uses specified table name' do
        expect(parsed_partition.table).to eq(table)
      end

      it 'uses specified partition name' do
        expect(parsed_partition.partition_name).to eq(partition_name)
      end

      it 'parses the definition' do
        expect(parsed_partition.values).to eq([partition_value])
      end
    end

    context 'with multiple partition values' do
      let(:partition_values) { [10, 11, 12] }
      let(:partition_name) { "partitioned_table_10_11_12" }
      let(:definition) { "FOR VALUES IN ('10', '11', '12')" }

      it 'uses specified table name' do
        expect(parsed_partition.table).to eq(table)
      end

      it 'uses specified partition name' do
        expect(parsed_partition.partition_name).to eq(partition_name)
      end

      it 'parses the definition' do
        expect(parsed_partition.values).to eq(partition_values)
      end
    end
  end

  describe '#partition_name' do
    it 'is the explicit name if provided' do
      parsed_partition = described_class.new('table', 1, partition_name: 'some_other_name')

      expect(parsed_partition.partition_name).to eq('some_other_name')
    end

    it 'defaults to the table name followed by the partition value' do
      expect(described_class.new('table', 1).partition_name).to eq('table_1')
    end
  end

  describe 'sorting' do
    it 'is incomparable if the tables do not match' do
      expect(described_class.new('table1', 1) <=> described_class.new('table2', 2)).to be_nil
    end

    it 'sorts by the value when the tables match' do
      expect(described_class.new('table1', 1) <=> described_class.new('table1', 2)).to eq(1 <=> 2)
    end

    it 'sorts by numeric value rather than text value' do
      expect(described_class.new('table', 10)).to be > described_class.new('table', 9)
    end

    it 'sorts with array values' do
      expect(described_class.new('table1',
        [10, 11]) <=> described_class.new('table1', [12, 13])).to eq([10, 11] <=> [12, 13])
    end
  end

  describe '#hash' do
    let(:data) { { described_class.new('table', 10) => 1 } }

    it { expect(data.key?(described_class.new('table', 10))).to be_truthy }
    it { expect(data.key?(described_class.new('table', 9))).to be_falsey }
  end

  describe '#data_size' do
    it 'returns the partition size' do
      partition = Gitlab::Database::PostgresPartition.for_parent_table(:p_ci_builds).last
      parsed_partition = described_class.from_sql(:p_ci_builds, partition.name, partition.condition,
        schema: partition.schema)

      expect(parsed_partition.data_size).not_to eq(0)
    end
  end

  describe '#to_sql' do
    subject(:partition) { described_class.new('table', 10) }

    it 'generates SQL' do
      sql = 'CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."table_10" PARTITION OF "table" FOR VALUES IN (10)'
      expect(partition.to_sql).to eq(sql)
    end
  end

  describe '#to_detach_sql' do
    subject(:partition) { described_class.new('table', 10) }

    it 'generates SQL' do
      sql = 'ALTER TABLE "table" DETACH PARTITION "gitlab_partitions_dynamic"."table_10"'
      expect(partition.to_detach_sql).to eq(sql)
    end
  end

  describe '#before?' do
    let(:database_partition) { described_class.new('table', 10) }

    subject(:before) { database_partition.before?(partition_id) }

    context 'when partition_id is before the max partition value' do
      let(:partition_id)  { 9 }

      it { is_expected.to be_falsey }
    end

    context 'when partition_id is after the max partition value' do
      let(:partition_id) { 11 }

      it { is_expected.to be_truthy }
    end
  end
end
