require 'spec_helper'

describe Github::Client do
  let(:connection) { spy }
  let(:rate_limit) { double(get: [false, 1]) }
  let(:client) { described_class.new({}) }
  let(:results) { double }
  let(:response) { double }

  before do
    allow(Faraday).to receive(:new).and_return(connection)
    allow(Github::RateLimit).to receive(:new).with(connection).and_return(rate_limit)
  end

  describe '#get' do
    before do
      allow(Github::Response).to receive(:new).with(results).and_return(response)
    end

    it 'uses a default per_page param' do
      expect(connection).to receive(:get).with('/foo', per_page: 100).and_return(results)

      expect(client.get('/foo')).to eq(response)
    end

    context 'with per_page given' do
      it 'overwrites the default per_page' do
        expect(connection).to receive(:get).with('/foo', per_page: 30).and_return(results)

        expect(client.get('/foo', per_page: 30)).to eq(response)
      end
    end
  end
end
