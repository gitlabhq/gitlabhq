require 'spec_helper'

describe Geo::NodeStatusService, services: true do
  let!(:primary)  { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  subject { described_class.new }

  before do
    allow(described_class).to receive(:current_node) { primary }
  end

  describe '#call' do
    it 'parses a 401 response' do
      request = double(success?: false,
                       code: 401,
                       message: 'Unauthorized',
                       parsed_response: { 'message' => 'Test' } )
      allow(described_class).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status.health).to eq("Could not connect to Geo node - HTTP Status Code: 401 Unauthorized\nTest")
    end

    it 'parses a 200 response' do
      data = { health: 'OK',
               repositories_count: 10,
               repositories_synced_count: 1,
               repositories_failed_count: 2,
               lfs_objects_count: 100,
               lfs_objects_synced_count: 50,
               attachments_count: 30,
               attachments_synced_count: 30 }
      request = double(success?: true, parsed_response: data.stringify_keys, code: 200)
      allow(described_class).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status).to have_attributes(data)
    end

    it 'omits full response text in status' do
      request = double(success?: false,
                       code: 401,
                       message: 'Unauthorized',
                       parsed_response: '<html><h1>You are not allowed</h1></html>')
      allow(described_class).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status.health).to eq("Could not connect to Geo node - HTTP Status Code: 401 Unauthorized\n")
    end
  end
end
