# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::SingleNumericListPartition, feature_category: :database do
  describe '.from_sql' do
    subject(:parsed_partition) { described_class.from_sql(table, partition_name, definition) }

    let(:table) { 'partitioned_table' }
    let(:partition_value) { 0 }
    let(:partition_name) { "partitioned_table_#{partition_value}" }
    let(:definition) { "FOR VALUES IN ('#{partition_value}')" }

    it 'uses specified table name' do
      expect(parsed_partition.table).to eq(table)
    end

    it 'uses specified partition name' do
      expect(parsed_partition.partition_name).to eq(partition_name)
    end

    it 'parses the definition' do
      expect(parsed_partition.value).to eq(partition_value)
    end
  end

  describe '#partition_name' do
    it 'is the explicit name if provided' do
      expect(described_class.new('table', 1, partition_name: 'some_other_name').partition_name).to eq('some_other_name')
    end

    it 'defaults to the table name followed by the partition value' do
      expect(described_class.new('table', 1).partition_name).to eq('table_1')
    end
  end

  describe '.from_export_definition' do
    let(:table) { 'table' }
    let(:partition_name) { 'table_10' }

    it 'parses symbol-key hash', :aggregate_failures do
      partition = described_class.from_export_definition(table, partition_name, { values: [10] })

      expect(partition.table).to eq(table)
      expect(partition.partition_name).to eq(partition_name)
      expect(partition.value).to eq(10)
    end

    it 'parses string-key hash (JSON-parsed input)' do
      partition = described_class.from_export_definition(table, partition_name, { 'values' => ['10'] })

      expect(partition.value).to eq(10)
    end

    it 'raises ArgumentError for non-integer values' do
      expect { described_class.from_export_definition(table, partition_name, { values: ['abc'] }) }
        .to raise_error(ArgumentError)
    end

    it 'raises ArgumentError for multi-value input' do
      expect { described_class.from_export_definition(table, partition_name, { values: [10, 11] }) }
        .to raise_error(ArgumentError, /single value/)
    end

    it 'roundtrips through export_definition', :aggregate_failures do
      original = described_class.new(table, 10, partition_name: partition_name)
      restored = described_class.from_export_definition(table, partition_name, original.export_definition)

      expect(restored.value).to eq(original.value)
      expect(restored.partition_name).to eq(original.partition_name)
    end
  end

  describe '#export_definition' do
    it 'returns a hash with partition_name and values as a single-element array' do
      partition = described_class.new('table', 10, partition_name: 'table_10')

      expect(partition.export_definition).to eq({ partition_name: 'table_10', values: [10] })
    end
  end

  describe '#covers?' do
    let(:partition) { described_class.new('table', 10) }

    it 'returns true for an exact value match' do
      expect(partition.covers?(described_class.new('table', 10))).to be(true)
    end

    it 'returns false for a different value' do
      expect(partition.covers?(described_class.new('table', 11))).to be(false)
    end
  end

  context 'sorting' do
    it 'is incomparable if the tables do not match' do
      expect(described_class.new('table1', 1) <=> described_class.new('table2', 2)).to be_nil
    end

    it 'sorts by the value when the tables match' do
      expect(described_class.new('table1', 1) <=> described_class.new('table1', 2)).to eq(1 <=> 2)
    end

    it 'sorts by numeric value rather than text value' do
      expect(described_class.new('table', 10)).to be > described_class.new('table', 9)
    end
  end
end
