# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::ClickHouseConnection, :click_house, feature_category: :database do
  include GraphqlHelpers

  let_it_be(:event_4) { create(:closed_issue_event, created_at: 1.year.ago) }
  let_it_be(:event_2) { create(:closed_issue_event, created_at: 3.years.ago) }
  let_it_be(:event_1) { create(:closed_issue_event, created_at: 4.years.ago) }
  let_it_be(:event_3) { create(:closed_issue_event, created_at: 2.years.ago) }

  let(:nodes) do
    ClickHouse::Client::QueryBuilder
      .new('events')
      .select(:id, :created_at)
      .where(target_type: 'Issue')
      .order(:created_at, :asc)
      .order(:id, :asc)
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

  def decoded_cursor(cursor)
    Gitlab::Json.parse(Base64.urlsafe_decode64(cursor))
  end

  describe '#nodes' do
    let(:expected_order) { [event_1.id, event_2.id, event_3.id, event_4.id] }

    subject(:ids) { connection.nodes.pluck("id") }

    it 'returns records for the first page' do
      expect(ids).to eq(expected_order.first(3))

      expect(connection.has_previous_page).to be_falsey
      expect(connection.has_next_page).to be_truthy
    end

    context 'when the first argument is given' do
      let(:arguments) { { first: 2 } }

      it 'returns records for the first page' do
        expect(ids).to eq(expected_order.first(2))

        expect(connection.has_previous_page).to be_falsey
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when the last argument is given' do
      let(:arguments) { { last: 2 } }

      it 'returns records for the first page' do
        expect(ids).to eq([expected_order[2], expected_order[3]])

        expect(connection.has_previous_page).to be_truthy
        expect(connection.has_next_page).to be_falsey
      end
    end

    context 'when after is passed' do
      let(:arguments) { { after: encoded_cursor({ "id" => event_2.id, "created_at" => event_2.created_at }) } }

      it 'only returns the events after the selected one' do
        expect(ids).to eq(expected_order.last(2))

        expect(connection.has_previous_page).to be_truthy
        expect(connection.has_next_page).to be_falsey
      end
    end

    context 'when before is passed' do
      let(:arguments) { { before: encoded_cursor({ "id" => event_2.id, "created_at" => event_2.created_at }) } }

      it 'only returns the events before the selected one' do
        expect(ids).to eq([expected_order[0]])

        expect(connection.has_previous_page).to be_falsey
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when after and before are passed' do
      let(:arguments) do
        {
          after: encoded_cursor({ "id" => event_1.id, "created_at" => event_1.created_at }),
          before: encoded_cursor({ "id" => event_3.id, "created_at" => event_3.created_at })
        }
      end

      it 'only returns events between the cursors' do
        expect(ids).to eq([event_2.id])

        expect(connection.has_previous_page).to be_truthy
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when before and last are passed' do
      let(:arguments) do
        {
          last: 2,
          before: encoded_cursor({ "id" => event_4.id, "created_at" => event_4.created_at })
        }
      end

      it 'only returns events between the cursors' do
        expect(ids).to eq([event_2.id, event_3.id])

        expect(connection.has_previous_page).to be_truthy
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when before and first are passed' do
      let(:arguments) do
        {
          first: 2,
          before: encoded_cursor({ "id" => event_3.id, "created_at" => event_3.created_at })
        }
      end

      it 'only returns events between the cursors' do
        expect(ids).to eq([expected_order[0], expected_order[1]])

        expect(connection.has_previous_page).to be_falsey
        expect(connection.has_next_page).to be_truthy
      end
    end

    context 'when bogus cursor is given' do
      let(:arguments) { { after: "YQ" } }

      it 'raises error' do
        expect { ids }.to raise_error(/Invalid cursor/)
      end
    end

    context 'when SQL injection is attempted' do
      let(:arguments) do
        {
          # Safe: (created_at, id) > (2025-01-01, 1)
          # With SQL injection:  (created_at, id) > (2025-01-01, 1) OR 1=1--)
          after: encoded_cursor({ "id" => "1) OR 1=1--", "created_at" => event_1.created_at })
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

  describe 'cursor generation' do
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
