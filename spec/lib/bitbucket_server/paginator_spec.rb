require 'spec_helper'

describe BitbucketServer::Paginator do
  let(:last_page) { double(:page, next?: false, items: ['item_2']) }
  let(:first_page) { double(:page, next?: true, next: last_page, items: ['item_1']) }
  let(:connection) { instance_double(BitbucketServer::Connection) }

  describe '#items' do
    let(:paginator) { described_class.new(connection, 'http://more-data', :pull_request) }
    let(:page_attrs) { { 'isLastPage' => false, 'nextPageStart' => 1 } }

    it 'returns items and raises StopIteration in the end' do
      allow(paginator).to receive(:fetch_next_page).and_return(first_page)
      expect(paginator.items).to match(['item_1'])

      allow(paginator).to receive(:fetch_next_page).and_return(last_page)
      expect(paginator.items).to match(['item_2'])

      allow(paginator).to receive(:fetch_next_page).and_return(nil)
      expect { paginator.items }.to raise_error(StopIteration)
    end

    it 'calls the connection with different offsets' do
      expect(connection).to receive(:get).with('http://more-data', start: 0, limit: BitbucketServer::Paginator::PAGE_LENGTH).and_return(page_attrs)

      expect(paginator.items).to eq([])

      expect(connection).to receive(:get).with('http://more-data', start: 1, limit: BitbucketServer::Paginator::PAGE_LENGTH).and_return({})

      expect(paginator.items).to eq([])

      expect { paginator.items }.to raise_error(StopIteration)
    end
  end
end
