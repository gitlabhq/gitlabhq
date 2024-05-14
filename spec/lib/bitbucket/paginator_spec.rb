# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Paginator, feature_category: :importers do
  let(:last_page) { double(:page, next?: false, items: ['item_3']) }
  let(:second_page) { double(:page, next?: true, next: last_page, items: ['item_2']) }
  let(:first_page) { double(:page, next?: true, next: second_page, items: ['item_1']) }

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
end
