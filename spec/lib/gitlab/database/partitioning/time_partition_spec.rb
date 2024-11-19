# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::TimePartition, feature_category: :database do
  describe '.from_sql' do
    subject { described_class.from_sql(table, partition_name, definition) }

    let(:table) { 'foo' }
    let(:partition_name) { 'foo_bar' }
    let(:definition) { 'FOR VALUES FROM (\'2020-04-01 00:00:00\') TO (\'2020-05-01 00:00:00\')' }

    it 'uses specified table name' do
      expect(subject.table).to eq(table)
    end

    it 'uses specified partition name' do
      expect(subject.partition_name).to eq(partition_name)
    end

    it 'parses start date' do
      expect(subject.from).to eq(Date.parse('2020-04-01'))
    end

    it 'parses end date' do
      expect(subject.to).to eq(Date.parse('2020-05-01'))
    end

    context 'with MINVALUE as a start date' do
      let(:definition) { 'FOR VALUES FROM (MINVALUE) TO (\'2020-05-01\')' }

      it 'sets from to nil' do
        expect(subject.from).to be_nil
      end
    end

    context 'with MAXVALUE as an end date' do
      let(:definition) { 'FOR VALUES FROM (\'2020-04-01\') TO (MAXVALUE)' }

      it 'raises a NotImplementedError' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#to_sql' do
    subject { described_class.new(table, from, to, partition_name: partition_name).to_sql }

    let(:table) { 'foo' }
    let(:from) { '2020-04-01 00:00:00' }
    let(:to) { '2020-05-01 00:00:00' }
    let(:suffix) { '202004' }
    let(:partition_name) { "#{table}_#{suffix}" }

    it 'transforms to a CREATE TABLE statement' do
      expect(subject).to eq(<<~SQL)
        CREATE TABLE IF NOT EXISTS "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}"."foo_202004"
        PARTITION OF "foo"
        FOR VALUES FROM ('2020-04-01') TO ('2020-05-01')
      SQL
    end

    context 'without from date' do
      let(:from) { nil }
      let(:suffix) { '000000' }

      it 'uses MINVALUE instead' do
        expect(subject).to eq(<<~SQL)
          CREATE TABLE IF NOT EXISTS "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}"."foo_000000"
          PARTITION OF "foo"
          FOR VALUES FROM (MINVALUE) TO ('2020-05-01')
        SQL
      end
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

    def make_new(table: 'foo', from: '2020-04-01 00:00:00', to: '2020-05-01 00:00:00', partition_name: 'foo_202004')
      described_class.new(table, from, to, partition_name: partition_name)
    end

    it 'treats objects identical with identical attributes' do
      expect_equality(make_new, make_new)
    end

    it 'different table leads to in-equality' do
      expect_inequality(make_new, make_new(table: 'bar'))
    end

    it 'different from leads to in-equality' do
      expect_inequality(make_new, make_new(from: '2020-05-01 00:00:00'))
    end

    it 'different to leads to in-equality' do
      expect_inequality(make_new, make_new(to: '2020-06-01 00:00:00'))
    end

    it 'different partition_name leads to in-equality' do
      expect_inequality(make_new, make_new(partition_name: 'different'))
    end

    it 'raises en error if partition_name is nil' do
      expect { make_new(partition_name: nil) }.to raise_error(ArgumentError, "partition_name required but none given")
    end
  end

  describe 'Comparable, #<=>' do
    let(:table) { 'foo' }

    it 'sorts by partition name, i.e. by month - MINVALUE partition first' do
      partitions = [
        described_class.new(table, '2020-04-01', '2020-05-01', partition_name: "#{table}_202004"),
        described_class.new(table, '2020-02-01', '2020-03-01', partition_name: "#{table}_202002"),
        described_class.new(table, nil, '2020-02-01', partition_name: "#{table}_000000"),
        described_class.new(table, '2020-03-01', '2020-04-01', partition_name: "#{table}_202003")
      ]

      expect(partitions.sort).to eq(
        [
          described_class.new(table, nil, '2020-02-01', partition_name: "#{table}_000000"),
          described_class.new(table, '2020-02-01', '2020-03-01', partition_name: "#{table}_202002"),
          described_class.new(table, '2020-03-01', '2020-04-01', partition_name: "#{table}_202003"),
          described_class.new(table, '2020-04-01', '2020-05-01', partition_name: "#{table}_202004")
        ])
    end

    it 'returns nil for partitions of different tables' do
      one = described_class.new('foo', '2020-02-01', '2020-03-01', partition_name: 'foo_202002')
      two = described_class.new('bar', '2020-02-01', '2020-03-01', partition_name: 'bar_202002')

      expect(one.<=>(two)).to be_nil
    end
  end
end
