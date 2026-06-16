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

  describe '#to_create_sql' do
    subject { described_class.new(table, from, to, partition_name: partition_name).to_create_sql }

    let(:table) { 'foo' }
    let(:from) { '2020-04-01 00:00:00' }
    let(:to) { '2020-05-01 00:00:00' }
    let(:suffix) { '202004' }
    let(:partition_name) { "#{table}_#{suffix}" }

    it 'creates a table with LIKE statement' do
      expect(subject).to eq(<<~SQL)
        CREATE TABLE IF NOT EXISTS "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}"."foo_202004"
        (LIKE "foo" INCLUDING ALL)
      SQL
    end
  end

  describe '#to_attach_sql' do
    subject { described_class.new(table, from, to, partition_name: partition_name).to_attach_sql }

    let(:table) { 'foo' }
    let(:from) { '2020-04-01 00:00:00' }
    let(:to) { '2020-05-01 00:00:00' }
    let(:suffix) { '202004' }
    let(:partition_name) { "#{table}_#{suffix}" }

    it 'creates an ALTER TABLE ATTACH PARTITION statement' do
      expect(subject).to eq(<<~SQL)
        ALTER TABLE "foo"
        ATTACH PARTITION "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}"."foo_202004"
        FOR VALUES FROM ('2020-04-01') TO ('2020-05-01')
      SQL
    end

    context 'without from date' do
      let(:from) { nil }
      let(:suffix) { '000000' }

      it 'uses MINVALUE instead' do
        expect(subject).to eq(<<~SQL)
          ALTER TABLE "foo"
          ATTACH PARTITION "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}"."foo_000000"
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

  describe '#export_definition' do
    it 'returns partition_name, from, and to as ISO 8601 strings' do
      partition = described_class.new('foo', '2020-04-01', '2020-05-01', partition_name: 'foo_202004')

      expect(partition.export_definition).to eq(
        { partition_name: 'foo_202004', from: '2020-04-01', to: '2020-05-01' }
      )
    end

    it 'returns nil for from when the partition starts at MINVALUE' do
      partition = described_class.new('foo', nil, '2020-05-01', partition_name: 'foo_000000')

      expect(partition.export_definition).to eq(
        { partition_name: 'foo_000000', from: nil, to: '2020-05-01' }
      )
    end
  end

  describe '.from_export_definition' do
    let(:table) { 'foo' }
    let(:partition_name) { 'foo_202004' }

    it 'parses symbol-key hash' do
      partition = described_class.from_export_definition(table, partition_name,
        { from: '2020-04-01', to: '2020-05-01' })

      expect(partition.from).to eq(Date.parse('2020-04-01'))
      expect(partition.to).to eq(Date.parse('2020-05-01'))
      expect(partition.partition_name).to eq(partition_name)
    end

    it 'parses string-key hash (JSON-parsed input)' do
      partition = described_class.from_export_definition(table, partition_name,
        { 'from' => '2020-04-01', 'to' => '2020-05-01' })

      expect(partition.from).to eq(Date.parse('2020-04-01'))
      expect(partition.to).to eq(Date.parse('2020-05-01'))
    end

    it 'handles nil from (MINVALUE partition)' do
      partition = described_class.from_export_definition(table, 'foo_000000', { from: nil, to: '2020-05-01' })

      expect(partition.from).to be_nil
      expect(partition.to).to eq(Date.parse('2020-05-01'))
    end

    it 'raises ArgumentError for an invalid date string' do
      expect { described_class.from_export_definition(table, partition_name, { from: 'not-a-date', to: '2020-05-01' }) }
        .to raise_error(ArgumentError)
    end

    it 'roundtrips through export_definition' do
      original = described_class.new(table, '2020-04-01', '2020-05-01', partition_name: partition_name)
      restored = described_class.from_export_definition(table, partition_name, original.export_definition)

      expect(restored.from).to eq(original.from)
      expect(restored.to).to eq(original.to)
    end

    it 'roundtrips a MINVALUE partition through export_definition' do
      original = described_class.new(table, nil, '2020-05-01', partition_name: 'foo_000000')
      restored = described_class.from_export_definition(table, 'foo_000000', original.export_definition)

      expect(restored.from).to be_nil
      expect(restored.to).to eq(original.to)
    end
  end

  describe '#covers?' do
    def make_partition(from, to)
      suffix = from ? Date.parse(from.to_s).strftime('%Y%m') : '000000'
      described_class.new('foo', from, to, partition_name: "foo_#{suffix}")
    end

    let(:partition) { make_partition('2020-03-01', '2020-06-01') }

    it 'returns true for exact same bounds' do
      expect(partition.covers?(make_partition('2020-03-01', '2020-06-01'))).to be(true)
    end

    it 'returns true when other is strictly contained' do
      expect(partition.covers?(make_partition('2020-04-01', '2020-05-01'))).to be(true)
    end

    it 'returns true when other has the same lower bound and a narrower upper bound' do
      expect(partition.covers?(make_partition('2020-03-01', '2020-05-01'))).to be(true)
    end

    it 'returns true when other has a wider lower bound and the same upper bound' do
      expect(partition.covers?(make_partition('2020-04-01', '2020-06-01'))).to be(true)
    end

    it 'returns false when other extends beyond the upper bound' do
      expect(partition.covers?(make_partition('2020-03-01', '2020-07-01'))).to be(false)
    end

    it 'returns false when other starts before the lower bound' do
      expect(partition.covers?(make_partition('2020-02-01', '2020-06-01'))).to be(false)
    end

    it 'returns false when ranges do not overlap' do
      expect(partition.covers?(make_partition('2020-07-01', '2020-08-01'))).to be(false)
    end

    it 'returns false when other completely contains self' do
      expect(partition.covers?(make_partition('2020-01-01', '2020-08-01'))).to be(false)
    end

    context 'when self has a MINVALUE lower bound (nil from)' do
      let(:partition) { make_partition(nil, '2026-05-01') }

      it 'returns true for a bounded partition within the range' do
        expect(partition.covers?(make_partition('2020-01-01', '2020-02-01'))).to be(true)
      end

      it 'returns true for another MINVALUE partition with the same upper bound' do
        expect(partition.covers?(make_partition(nil, '2026-05-01'))).to be(true)
      end

      it 'returns false when other extends beyond the upper bound' do
        expect(partition.covers?(make_partition('2020-01-01', '2026-06-01'))).to be(false)
      end
    end

    context 'when other has a MINVALUE lower bound (nil from)' do
      it 'returns false when self has a bounded lower bound' do
        expect(partition.covers?(make_partition(nil, '2020-06-01'))).to be(false)
      end
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
