# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Connections::ExternallyPaginatedArrayConnection do
  let(:prev_cursor) { 1 }
  let(:next_cursor) { 6 }
  let(:values) { [2, 3, 4, 5] }
  let(:all_nodes) { Gitlab::Graphql::ExternallyPaginatedArray.new(prev_cursor, next_cursor, *values) }
  let(:arguments) { {} }

  subject(:connection) do
    described_class.new(all_nodes, arguments)
  end

  describe '#sliced_nodes' do
    let(:sliced_nodes) { connection.sliced_nodes }

    it 'returns all the nodes' do
      expect(connection.sliced_nodes).to eq(values)
    end
  end

  describe '#paged_nodes' do
    let(:paged_nodes) { connection.send(:paged_nodes) }

    it_behaves_like "connection with paged nodes" do
      let(:paged_nodes_size) { values.size }
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
  end
end
