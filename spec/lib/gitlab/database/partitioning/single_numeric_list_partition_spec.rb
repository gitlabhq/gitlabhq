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
