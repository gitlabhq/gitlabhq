# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::IntRangePartition, feature_category: :database do
  describe 'validate attributes' do
    subject(:int_range_partition) { described_class.from_sql(table, partition_name, definition) }

    let(:table) { 'foo' }
    let(:partition_name) { 'foo_bar' }
    let(:definition) { "FOR VALUES FROM ('1') TO ('10')" }

    context 'when `from` is greater than `to`' do
      let(:definition) { "FOR VALUES FROM ('10') TO ('1')" }

      it 'raises an exception' do
        expect { int_range_partition }.to raise_error(RuntimeError, '`to` must be greater than `from`')
      end
    end

    context 'when `to` is 0' do
      let(:definition) { "FOR VALUES FROM ('10') TO ('0')" }

      it 'raises an exception' do
        expect { int_range_partition }.to raise_error(RuntimeError, '`to` statement must be greater than 0')
      end
    end

    context 'when `from` is 0' do
      let(:definition) { "FOR VALUES FROM ('0') TO ('1')" }

      it 'raises an exception' do
        expect { int_range_partition }.to raise_error(RuntimeError, '`from` statement must be greater than 0')
      end
    end
  end

  describe '.from_sql' do
    subject(:int_range_partition) { described_class.from_sql(table, partition_name, definition) }

    let(:table) { 'foo' }
    let(:partition_name) { 'foo_bar' }
    let(:definition) { "FOR VALUES FROM ('1') TO ('10')" }

    it 'uses specified table name' do
      expect(int_range_partition.table).to eq(table)
    end

    it 'uses specified partition name' do
      expect(int_range_partition.partition_name).to eq(partition_name)
    end

    it 'parses start date' do
      expect(int_range_partition.from).to eq(1)
    end

    it 'parses end date' do
      expect(int_range_partition.to).to eq(10)
    end
  end

  describe '#partition_name' do
    subject(:int_range_partition_name) do
      described_class.new(table, from, to, partition_name: partition_name).partition_name
    end

    let(:table) { 'foo' }
    let(:from) { '1' }
    let(:to) { '10' }
    let(:partition_name) { nil }

    it 'uses table as prefix' do
      expect(int_range_partition_name).to start_with(table)
    end

    it 'uses start id (from) as suffix' do
      expect(int_range_partition_name).to end_with("_1")
    end

    context 'with partition name explicitly given' do
      let(:partition_name) { "foo_bar" }

      it 'uses given partition name' do
        expect(int_range_partition_name).to eq(partition_name)
      end
    end
  end

  describe '#to_sql' do
    subject(:to_sql) { described_class.new(table, from, to).to_sql }

    let(:table) { 'foo' }
    let(:from) { '1' }
    let(:to) { '10' }

    it 'transforms to a CREATE TABLE statement' do
      expect(to_sql).to eq(<<~SQL)
        CREATE TABLE IF NOT EXISTS "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}"."foo_1"
        PARTITION OF "foo"
        FOR VALUES FROM ('1') TO ('10')
      SQL
    end
  end

  describe 'object equality - #eql' do
    def expect_inequality(actual, other)
      expect(actual.eql?(other)).to be_falsey
      expect(actual).not_to eq(other)
    end

    def expect_equality(actual, other)
      expect(actual).to eq(other)
      expect(actual.eql?(other)).to be_truthy
      expect(actual.hash).to eq(other.hash)
    end

    def make_new(table: 'foo', from: '1', to: '10', partition_name: 'foo_1')
      described_class.new(table, from, to, partition_name: partition_name)
    end

    it 'treats objects identical with identical attributes' do
      expect_equality(make_new, make_new)
    end

    it 'different table leads to in-equality' do
      expect_inequality(make_new, make_new(table: 'bar'))
    end

    it 'different from leads to in-equality' do
      expect_inequality(make_new, make_new(from: '2'))
    end

    it 'different to leads to in-equality' do
      expect_inequality(make_new, make_new(to: '11'))
    end

    it 'different partition_name leads to in-equality' do
      expect_inequality(make_new, make_new(partition_name: 'different'))
    end

    it 'nil partition_name is ignored if auto-generated matches' do
      expect_equality(make_new, make_new(partition_name: nil))
    end
  end

  describe 'Comparable, #<=>' do
    let(:table) { 'foo' }

    it 'sorts by partition bounds' do
      partitions = [
        described_class.new(table, '100', '110', partition_name: 'p_100'),
        described_class.new(table, '5', '10', partition_name: 'p_5'),
        described_class.new(table, '10', '100', partition_name: 'p_10'),
        described_class.new(table, '1', '5', partition_name: 'p_1')
      ]

      expect(partitions.sort).to eq(
        [
          described_class.new(table, '1', '5', partition_name: 'p_1'),
          described_class.new(table, '5', '10', partition_name: 'p_5'),
          described_class.new(table, '10', '100', partition_name: 'p_10'),
          described_class.new(table, '100', '110', partition_name: 'p_100')
        ])
    end

    it 'returns nil for partitions of different tables' do
      one = described_class.new('foo', '1', '10')
      two = described_class.new('bar', '1', '10')

      expect(one.<=>(two)).to be_nil
    end
  end
end
