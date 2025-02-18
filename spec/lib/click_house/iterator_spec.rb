# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Iterator, :click_house, feature_category: :database do
  let(:query_builder) { ClickHouse::QueryBuilder.new('event_authors') }
  let(:connection) { ClickHouse::Connection.new(:main) }
  let(:min_max_strategy) { :min_max }
  let(:iterator) do
    described_class.new(
      query_builder: query_builder,
      connection: connection,
      min_max_strategy: min_max_strategy
    )
  end

  before do
    connection.execute('INSERT INTO event_authors (author_id) SELECT number + 1 FROM numbers(10)')
  end

  def collect_ids_with_batch_size(of)
    [].tap do |ids|
      iterator.each_batch(column: :author_id, of: of) do |scope|
        query = scope.select(Arel.sql('DISTINCT author_id')).to_sql
        ids.concat(connection.select(query).pluck('author_id'))
      end
    end
  end

  it 'iterates correctly' do
    expected_values = (1..10).to_a

    expect(collect_ids_with_batch_size(3)).to match_array(expected_values)
    expect(collect_ids_with_batch_size(5)).to match_array(expected_values)
    expect(collect_ids_with_batch_size(10)).to match_array(expected_values)
    expect(collect_ids_with_batch_size(15)).to match_array(expected_values)
  end

  context 'when invalid min_max_strategy is given' do
    let(:min_max_strategy) { :unknown }

    it 'raises ArgumentError' do
      expect { collect_ids_with_batch_size(3) }.to raise_error(ArgumentError, /Unknown min_max/)
    end
  end

  context 'when order_limit min_max_strategy is given' do
    let(:min_max_strategy) { :order_limit }

    it 'iterates correctly' do
      expected_values = (1..10).to_a

      expect(collect_ids_with_batch_size(3)).to match_array(expected_values)
      expect(collect_ids_with_batch_size(5)).to match_array(expected_values)
      expect(collect_ids_with_batch_size(10)).to match_array(expected_values)
      expect(collect_ids_with_batch_size(15)).to match_array(expected_values)
    end
  end

  it 'yields the boundary values' do
    min_values = []
    max_values = []

    iterator.each_batch(column: :author_id, of: 2) do |_scope, min, max|
      min_values << min
      max_values << max
    end

    expect(min_values).to eq([1, 3, 5, 7, 9])
    expect(max_values).to eq([2, 4, 6, 8, 10])
  end

  context 'when min value is given' do
    let(:iterator) { described_class.new(query_builder: query_builder, connection: connection, min_value: 5) }

    it 'iterates from the given min value' do
      expected_values = (5..10).to_a

      expect(collect_ids_with_batch_size(5)).to match_array(expected_values)
    end
  end

  context 'when there are no records for the given query' do
    let(:query_builder) do
      ClickHouse::QueryBuilder
        .new('event_authors')
        .where(author_id: 0)
    end

    it 'returns no data' do
      expect(collect_ids_with_batch_size(3)).to be_empty
    end
  end
end
