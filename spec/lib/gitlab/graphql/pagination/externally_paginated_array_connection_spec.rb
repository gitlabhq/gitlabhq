# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection do
  let(:context) { instance_double(GraphQL::Query::Context, schema: GitlabSchema) }
  let(:prev_cursor) { 1 }
  let(:next_cursor) { 6 }
  let(:values) { [2, 3, 4, 5] }
  let(:has_next_page_value) { nil }
  let(:has_previous_page_value) { nil }
  let(:arguments) { {} }
  let(:all_nodes) do
    Gitlab::Graphql::ExternallyPaginatedArray.new(
      prev_cursor,
      next_cursor,
      *values,
      has_next_page: has_next_page_value,
      has_previous_page: has_previous_page_value
    )
  end

  subject(:connection) do
    described_class.new(all_nodes, **{ context: context, max_page_size: values.size }.merge(arguments))
  end

  it_behaves_like 'a connection with collection methods'

  it_behaves_like 'a redactable connection' do
    let(:unwanted) { 3 }
  end

  describe '#nodes' do
    let(:paged_nodes) { connection.nodes }

    it_behaves_like 'connection with paged nodes' do
      let(:paged_nodes_size) { values.size }
    end

    context 'when after or before is specified, they are ignored' do
      # after and before are not used to filter the array, as they
      # were already used to directly fetch the external array
      it_behaves_like 'connection with paged nodes' do
        let(:arguments) { { after: next_cursor } }
        let(:paged_nodes_size) { values.size }
      end

      it_behaves_like 'connection with paged nodes' do
        let(:arguments) { { before: prev_cursor } }
        let(:paged_nodes_size) { values.size }
      end
    end
  end

  describe '#start_cursor' do
    it 'returns the prev cursor' do
      expect(connection.start_cursor).to eq(prev_cursor)
    end

    context 'when there is none' do
      let(:prev_cursor) { nil }

      it 'returns nil' do
        expect(connection.start_cursor).to eq(nil)
      end
    end
  end

  describe '#end_cursor' do
    it 'returns the next cursor' do
      expect(connection.end_cursor).to eq(next_cursor)
    end

    context 'when there is none' do
      let(:next_cursor) { nil }

      it 'returns nil' do
        expect(connection.end_cursor).to eq(nil)
      end
    end
  end

  describe '#has_next_page' do
    it 'returns true when there is a end cursor' do
      expect(connection.has_next_page).to eq(true)
    end

    context 'there is no end cursor' do
      let(:next_cursor) { nil }

      it 'returns false' do
        expect(connection.has_next_page).to eq(false)
      end
    end

    context 'when items have explicit has_next_page value' do
      context 'when has_next_page is true' do
        let(:has_next_page_value) { true }

        it 'returns true regardless of cursor presence' do
          expect(connection.has_next_page).to eq(true)
        end
      end

      context 'when has_next_page is false' do
        let(:has_next_page_value) { false }

        it 'returns false even when cursor is present' do
          expect(connection.has_next_page).to eq(false)
          expect(connection.end_cursor).to eq(next_cursor)
        end
      end

      context 'when has_next_page is nil' do
        let(:has_next_page_value) { nil }

        it 'falls back to cursor presence check' do
          expect(connection.has_next_page).to eq(true)
        end
      end
    end
  end

  describe '#has_previous_page' do
    it 'returns true when there is a start cursor' do
      expect(connection.has_previous_page).to eq(true)
    end

    context 'there is no start cursor' do
      let(:prev_cursor) { nil }

      it 'returns false' do
        expect(connection.has_previous_page).to eq(false)
      end
    end

    context 'when items have explicit has_previous_page value' do
      context 'when has_previous_page is true' do
        let(:has_previous_page_value) { true }

        it 'returns true regardless of cursor presence' do
          expect(connection.has_previous_page).to eq(true)
        end
      end

      context 'when has_previous_page is false' do
        let(:has_previous_page_value) { false }

        it 'returns false even when cursor is present' do
          expect(connection.has_previous_page).to eq(false)
          expect(connection.start_cursor).to eq(prev_cursor)
        end
      end

      context 'when has_previous_page is nil' do
        let(:has_previous_page_value) { nil }

        it 'falls back to cursor presence check' do
          expect(connection.has_previous_page).to eq(true)
        end
      end
    end
  end
end
