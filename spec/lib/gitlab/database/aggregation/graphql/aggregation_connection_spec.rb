# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Graphql::AggregationConnection, :click_house, feature_category: :database do
  include GraphqlHelpers
  include ClickHouseHelpers

  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:event1) { create(:event, author: user1) }
  let_it_be(:event2) { create(:event, author: user1) }
  let_it_be(:event3) { create(:event, author: user2) }
  let_it_be(:event4) { create(:event, author: user3) }
  let_it_be(:event5) { create(:event, author: user3) }
  let_it_be(:event6) { create(:event, author: user3) }

  let(:arguments) { {} }
  let(:ctx) { GraphQL::Query::Context.new(query: query_double, values: nil) }

  let(:engine) { engine_definition.new(context: { scope: query_builder }) }
  let(:query_builder) { query }

  let(:aggregation_request) do
    Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :author_id }],
      metrics: [{ identifier: :total_count }],
      order: [{ identifier: :total_count, direction: :desc }]
    )
  end

  let(:nodes) do
    engine.execute(aggregation_request).payload[:data]
  end

  subject(:connection) do
    described_class.new(nodes, **{ context: ctx, max_page_size: 3 }.merge(arguments))
  end

  context 'when using ClickHouse aggregation engine', :aggregate_failures do
    let(:query) { ClickHouse::Client::QueryBuilder.new('events') }

    let(:engine_definition) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_primary_key = %w[id]

        dimensions do
          column :author_id, :integer
        end

        metrics do
          count
        end
      end
    end

    before do
      insert_events_into_click_house
    end

    context 'when requesting without pagination params' do
      let(:arguments) { {} }

      it 'returns the top max_page_size records' do
        expect(connection.nodes).to match([
          a_hash_including("author_id" => user3.id, "total_count" => 3),
          a_hash_including("author_id" => user1.id, "total_count" => 2),
          a_hash_including("author_id" => user2.id, "total_count" => 1)
        ])
        expect(connection.has_next_page).to be false
        expect(connection.has_previous_page).to be false
      end
    end

    context 'when requesting the first page' do
      let(:arguments) { { first: 2 } }

      it 'returns the top 2 records' do
        expect(connection.nodes).to match([
          a_hash_including("author_id" => user3.id, "total_count" => 3),
          a_hash_including("author_id" => user1.id, "total_count" => 2)
        ])
        expect(connection.has_next_page).to be true
        expect(connection.has_previous_page).to be false
      end

      it 'generates correct cursors' do
        node_1 = connection.nodes.first
        expect(connection.cursor_for(node_1)).to eq(encode_cursor(0))
      end
    end

    context 'when paginating with "after"' do
      let(:arguments) { { first: 2, after: encode_cursor(0) } }

      it 'returns the next records' do
        expect(connection.nodes).to match([
          a_hash_including("author_id" => user1.id, "total_count" => 2),
          a_hash_including("author_id" => user2.id, "total_count" => 1)
        ])
        expect(connection.has_next_page).to be false
        expect(connection.has_previous_page).to be true
      end
    end

    context 'when "after" is the last item' do
      let(:arguments) { { first: 2, after: encode_cursor(3) } }

      it 'returns empty list' do
        expect(connection.nodes).to be_empty
        expect(connection.has_next_page).to be false
        expect(connection.has_previous_page).to be true
      end
    end

    context 'when using last and before' do
      let(:arguments) { { last: 1, before: encode_cursor(2) } }

      it 'returns the preceding record' do
        expect(connection.nodes).to match([
          a_hash_including("author_id" => user1.id)
        ])
        expect(connection.has_next_page).to be true
        expect(connection.has_previous_page).to be true
      end
    end

    context 'when "last" is larger than available "before" records' do
      let(:arguments) { { last: 10, before: encode_cursor(2) } }

      it 'returns all preceding records up to the start' do
        expect(connection.nodes).to match([
          a_hash_including("author_id" => user3.id),
          a_hash_including("author_id" => user1.id)
        ])
        expect(connection.has_previous_page).to be false
        expect(connection.has_next_page).to be true
      end
    end

    context 'when "last" is provided without "before"' do
      let(:arguments) { { last: 2 } }

      it 'raises an execution error' do
        expect { connection.nodes }
          .to raise_error(GraphQL::ExecutionError, /Argument 'last' can only be used in conjunction with 'before'/)
      end
    end

    context 'when "last" is provided together with "first"' do
      let(:arguments) { { last: 2, first: 2, before: encode_cursor(5) } }

      it 'raises an execution error' do
        expect { connection.nodes }
          .to raise_error(GraphQL::ExecutionError, /Arguments 'last' and 'first' can't be used simultaneously/)
      end
    end

    context 'when cursor is not from current page' do
      let(:arguments) { { first: 2 } }

      it 'raises an execution error' do
        expect { connection.cursor_for(:uknown_node) }
          .to raise_error(GraphQL::ExecutionError, /Node not found in current batch/)
      end
    end

    context 'when cursor is negative' do
      let(:arguments) { { after: encode_cursor(-10) } }

      it 'raises an execution error' do
        expect { connection.cursor_for(:uknown_node) }
          .to raise_error(GraphQL::ExecutionError, /Invalid cursor provided/)
      end
    end
  end

  def encode_cursor(value)
    GitlabSchema.cursor_encoder.encode(value.to_s, nonce: true)
  end
end
