# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Iterator, :click_house, feature_category: :database do
  let(:query_builder) { ClickHouse::QueryBuilder.new('event_authors') }
  let(:connection) { ClickHouse::Connection.new(:main) }
  let(:iterator) { described_class.new(query_builder: query_builder, connection: connection) }

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

  context 'when there are no records for the given query' do
    let(:query_builder) do
      ClickHouse::QueryBuilder
        .new('event_authors')
        .where(author_id: 0)
    end

    it 'returns no data' do
      expect(collect_ids_with_batch_size(3)).to match_array([])
    end
  end
end
