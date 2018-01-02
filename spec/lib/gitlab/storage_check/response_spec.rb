require 'spec_helper'

describe Gitlab::StorageCheck::Response do
  let(:fake_json) do
    {
      check_interval: 42,
      results: [
        { storage: 'working', success: true },
        { storage: 'skipped', success: nil },
        { storage: 'failing', success: false }
      ]
    }.to_json
  end

  let(:fake_http_response) do
    fake_response = instance_double("Excon::Response - Status check")
    allow(fake_response).to receive(:status).and_return(200)
    allow(fake_response).to receive(:body).and_return(fake_json)
    allow(fake_response).to receive(:headers).and_return('Content-Type' => 'application/json')

    fake_response
  end
  let(:response) { described_class.new(fake_http_response) }

  describe '#valid?' do
    it 'is valid for a success response with parseable JSON' do
      expect(response).to be_valid
    end
  end

  describe '#check_interval' do
    it 'returns the result from the JSON' do
      expect(response.check_interval).to eq(42)
    end
  end

  describe '#responsive_shards' do
    it 'contains the names of working shards' do
      expect(response.responsive_shards).to contain_exactly('working')
    end
  end

  describe '#skipped_shards' do
    it 'contains the names of skipped shards' do
      expect(response.skipped_shards).to contain_exactly('skipped')
    end
  end

  describe '#failing_shards' do
    it 'contains the name of failing shards' do
      expect(response.failing_shards).to contain_exactly('failing')
    end
  end
end
