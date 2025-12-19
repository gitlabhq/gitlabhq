# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Paginator, feature_category: :importers do
  let(:last_page) { double(:page, next?: false, items: ['item_3'], attrs: { previous: 'prev_url' }) }
  let(:second_page) do
    double(:page, next?: true, next: last_page, items: ['item_2'],
      attrs: { next: 'next_url?after=cursor2', previous: 'prev_url' })
  end

  let(:first_page) do
    double(:page, next?: true, next: second_page, items: ['item_1'], attrs: { next: 'next_url?after=cursor1' })
  end

  shared_examples 'iterating over all items' do
    it 'returns all items and raises StopIteration in the end' do
      allow(paginator).to receive(:fetch_next_page).and_return(first_page)
      expect(paginator.items).to match(['item_1'])

      allow(paginator).to receive(:fetch_next_page).and_return(second_page)
      expect(paginator.items).to match(['item_2'])

      allow(paginator).to receive(:fetch_next_page).and_return(last_page)
      expect(paginator.items).to match(['item_3'])

      allow(paginator).to receive(:fetch_next_page).and_return(nil)
      expect { paginator.items }.to raise_error(StopIteration)
    end
  end

  describe 'items' do
    context 'without page_number or limit' do
      let(:paginator) { described_class.new(nil, nil, nil) }

      it_behaves_like 'iterating over all items'
    end

    context 'with only page_number set' do
      let(:paginator) { described_class.new(nil, nil, nil, page_number: 2) }

      it_behaves_like 'iterating over all items'
    end

    context 'with only limit set' do
      let(:paginator) { described_class.new(nil, nil, nil, limit: 1) }

      it 'raises StopIteration once the limit number of items are returned' do
        allow(paginator).to receive(:fetch_next_page).and_return(first_page)
        expect(paginator.items).to match(['item_1'])

        allow(paginator).to receive(:fetch_next_page).and_return(second_page)
        expect { paginator.items }.to raise_error(StopIteration)
      end
    end

    context 'with page_number and limit set' do
      let(:paginator) { described_class.new(nil, nil, nil, page_number: 2, limit: 1) }

      it 'returns the specific page of items' do
        allow(paginator).to receive(:fetch_next_page).and_return(second_page)
        expect(paginator.items).to match(['item_2'])

        allow(paginator).to receive(:fetch_next_page).and_return(last_page)
        expect { paginator.items }.to raise_error(StopIteration)
      end
    end
  end

  describe '#page_info' do
    let(:connection) { double(:connection) }
    let(:url) { 'test_url' }
    let(:type) { :repo }

    context 'when page has next and previous' do
      let(:page_with_next_and_prev) do
        double(:page,
          next?: true,
          next: 'https://api.bitbucket.org/2.0/repositories?after=2025-12-10T12:13:37.393445+00:00',
          attrs: {
            next: 'https://api.bitbucket.org/2.0/repositories?after=2025-12-10T12:13:37.393445+00:00',
            previous: 'prev_url'
          }
        )
      end

      it 'returns page info with correct cursor information' do
        paginator = described_class.new(connection, url, type, after_cursor: 'start_cursor')
        allow(paginator).to receive(:page).and_return(page_with_next_and_prev)

        page_info = paginator.page_info

        expect(page_info[:has_next_page]).to be(true)
        expect(page_info[:start_cursor]).to eq('start_cursor')
        expect(page_info[:end_cursor]).to eq('2025-12-10T12:13:37.393445 00:00')
      end
    end

    context 'when page has no next' do
      let(:last_page_without_next) do
        double(:page,
          next?: false,
          attrs: { previous: 'prev_url' }
        )
      end

      it 'returns page info with has_next_page as false and nil end_cursor' do
        paginator = described_class.new(connection, url, type)
        allow(paginator).to receive(:page).and_return(last_page_without_next)

        page_info = paginator.page_info

        expect(page_info[:has_next_page]).to be(false)
        expect(page_info[:start_cursor]).to be_nil
        expect(page_info[:end_cursor]).to be_nil
      end
    end
  end

  describe 'with after_cursor' do
    let(:connection) { double(:connection, get: { 'values' => [], 'next' => nil }) }
    let(:url) { 'test_url' }
    let(:type) { :repo }
    let(:after_cursor) { '2025-12-10T12:13:37.393445+00:00' }

    it 'passes after_cursor to connection on first fetch' do
      paginator = described_class.new(connection, url, type, after_cursor: after_cursor)

      expect(connection).to receive(:get).with(url, hash_including(after: after_cursor)).and_return(
        { 'values' => [], 'next' => nil }
      )

      paginator.items
    end

    it 'does not pass after_cursor on subsequent fetches' do
      next_page_response = { 'values' => [], 'next' => nil }
      paginator = described_class.new(connection, url, type, after_cursor: after_cursor)

      allow(connection).to receive(:get).with(url, hash_including(after: after_cursor)).and_return(
        { 'values' => ['item1'], 'next' => 'next_url' }
      )

      paginator.items

      # Second call should not include after parameter
      expect(connection).to receive(:get).with('next_url', hash_not_including(:after)).and_return(next_page_response)

      paginator.items
    end
  end
end
