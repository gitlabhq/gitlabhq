# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::ClickHouseConnection, :click_house, feature_category: :database do
  include GraphqlHelpers

  let(:nodes) do
    ClickHouse::Client::QueryBuilder
      .new('events')
      .select(:id)
      .order(:created_at, :asc)
      .order(:updated_at, :desc)
      .order(:id, :asc)
  end

  let_it_be(:ordered_events) do
    freeze_time do
      event_0 = create(:closed_issue_event, created_at: 1.year.ago, updated_at: 1.year.ago)
      event_1 = create(:closed_issue_event, created_at: 3.years.ago, updated_at: 1.year.ago)
      event_2 = create(:closed_issue_event, created_at: 4.years.ago, updated_at: 1.year.ago)
      event_3 = create(:closed_issue_event, created_at: 2.years.ago, updated_at: 2.years.ago)
      event_4 = create(:closed_issue_event, created_at: 2.years.ago, updated_at: 1.year.ago)

      [event_2, event_1, event_4, event_3, event_0]
    end
  end

  let(:clickhouse_connection) { ClickHouse::Connection.new(:main) }
  let(:context_values) { { connection: clickhouse_connection } }
  let(:context) { GraphQL::Query::Context.new(query: query_double, values: context_values) }

  let(:arguments) { {} }

  subject(:connection) do
    described_class.new(nodes, **{ context: context, max_page_size: 3 }.merge(arguments))
  end

  before do
    insert_events_into_click_house
  end

  def encoded_cursor(node)
    described_class.new(nodes, context: context).cursor_for(node)
  end

  describe '#nodes' do
    subject(:actual_ids) { connection.nodes.pluck("id") }

    context 'with pagination arguments' do
      using RSpec::Parameterized::TableSyntax

      where(:pagination_params, :expected_events_range, :expected_has_previous_page, :expected_has_next_page) do
        # No arguments - returns first 3 (max_page_size)
        {}                      | (0..2)   | false | true
        { first: 2 }            | (0..1)   | false | true
        { last: 2 }             | (-2..-1) | true  | false
        { after: 0 }            | (1..3)   | true  | true
        { after: 0, first: 2 }  | (1..2)   | true  | true
        { after: 0, last: 2 }   | (-2..-1) | true  | false
        { before: 2 }           | (0..1)   | false | true
        { before: 4, first: 2 } | (0..1)   | false | true
        { before: 3, last: 2 }  | (1..2)   | true  | true
        { after: 0, before: 2 } | (1..1)   | true  | true
      end

      with_them do
        let(:arguments) do
          args = pagination_params
          args[:after] = encoded_cursor(ordered_events[args[:after]]) if args[:after]
          args[:before] = encoded_cursor(ordered_events[args[:before]]) if args[:before]
          args
        end

        let(:expected_events) do
          ordered_events[expected_events_range]
        end

        it 'returns correct nodes and pagination info' do
          expect(actual_ids).to eq(expected_events.map(&:id))
          expect(connection.has_previous_page).to eq(expected_has_previous_page)
          expect(connection.has_next_page).to eq(expected_has_next_page)
        end
      end
    end

    context 'when clickhouse connection is not passed via context' do
      let(:context_values) { {} }

      it 'falls back to the main DB' do
        expect(actual_ids).to eq(ordered_events.first(3).map(&:id))
      end
    end

    context 'when bogus cursor is given' do
      let(:arguments) { { after: "YQ" } }

      it 'raises error' do
        expect { actual_ids }.to raise_error(/Invalid cursor/)
      end
    end

    context 'when SQL injection is attempted' do
      let(:arguments) do
        {
          # Safe: (created_at, updated_at, id) > (2025-01-01, 2025-01-01, 1)
          # With SQL injection:  (created_at, updated_at, id) > (2025-01-01, 2025-01-01, 1) OR 1=1--)
          after: encoded_cursor({
            "id" => "1) OR 1=1--",
            "created_at" => ordered_events.first.created_at,
            "updated_at" => ordered_events.first.updated_at
          })
        }
      end

      it 'escapes the strings correctly thus failing the query' do
        version = clickhouse_connection.select("SELECT version() AS ver").first['ver']

        # Special case: In ClickHouse 23, the HTTP interface will return empty
        # resultset and exception metadata with success status code.
        if version.start_with?("23")
          expect(connection.nodes.pluck("id")).to eq([])
        else
          # "1) OR 1=1--" input will be quoted with ''
          expect { connection.nodes.pluck("id") }.to raise_error(/Cannot convert string '1\) OR 1=1--' to type UInt64/)
        end
      end
    end
  end

  describe '#cursor_for' do
    let(:nodes) { ClickHouse::Client::QueryBuilder.new('events').order(:value, :asc) }

    def encode(string)
      Base64.urlsafe_encode64(string, padding: false)
    end

    it 'encodes numeric values' do
      expect(encoded_cursor({ 'value' => 1 })).to eq(encode('{"value":1}'))
      expect(encoded_cursor({ 'value' => 1.5 })).to eq(encode('{"value":1.5}'))
    end

    it 'encodes string value' do
      expect(encoded_cursor({ 'value' => 'foo bar' })).to eq(encode('{"value":"foo bar"}'))
    end

    it 'encodes datetime value' do
      time = Time.current
      expected = time.utc.strftime(described_class::TIME_PATTERN)
      expect(encoded_cursor({ 'value' => time })).to eq(encode(%({"value":"#{expected}"})))
    end

    it 'encodes date' do
      date = Time.zone.today
      expected = date.to_s

      expect(encoded_cursor({ 'value' => date })).to eq(encode(%({"value":"#{expected}"})))
    end

    context 'when cursor value is unsupported' do
      it 'raises error' do
        expect { encoded_cursor({ 'value' => Object.new }) }.to raise_error(/Unsupported type/)
      end
    end

    context 'when cursor value is nil' do
      it 'raises error because we expect not-nullable cursors' do
        expect { encoded_cursor({ 'value' => nil }) }.to raise_error(/missing/)
      end
    end
  end
end
