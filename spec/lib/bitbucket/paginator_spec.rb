require 'spec_helper'

describe Bitbucket::Paginator do
  let(:last_page) { double(:page, next?: false, items: ['item_2']) }
  let(:first_page) { double(:page, next?: true, next: last_page, items: ['item_1']) }

  describe 'items' do
    it 'return items and raises StopIteration in the end' do
      paginator = described_class.new(nil, nil, nil)

      allow(paginator).to receive(:fetch_next_page).and_return(first_page)
      expect(paginator.items).to match(['item_1'])

      allow(paginator).to receive(:fetch_next_page).and_return(last_page)
      expect(paginator.items).to match(['item_2'])

      allow(paginator).to receive(:fetch_next_page).and_return(nil)
      expect { paginator.items }.to raise_error(StopIteration)
    end
  end
end
