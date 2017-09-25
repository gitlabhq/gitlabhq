require 'spec_helper'

describe Geo::NodeStatusService do
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
               db_replication_lag: 0,
               repositories_count: 10,
               repositories_synced_count: 1,
               repositories_failed_count: 2,
               lfs_objects_count: 100,
               lfs_objects_synced_count: 50,
               attachments_count: 30,
               attachments_synced_count: 30,
               last_event_id: 2,
               last_event_date: Time.now,
               cursor_last_event_id: 1,
               cursor_last_event_date: Time.now }
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

    it 'alerts on bad SSL certficate' do
      message = 'bad certificate'
      allow(described_class).to receive(:get).and_raise(OpenSSL::SSL::SSLError.new(message))

      status = subject.call(secondary)

      expect(status.health).to eq(message)
    end

    it 'handles connection refused' do
      allow(described_class).to receive(:get).and_raise(Errno::ECONNREFUSED.new('bad connection'))

      status = subject.call(secondary)

      expect(status.health).to eq('Connection refused - bad connection')
    end

    it 'returns meaningful error message when primary uses incorrect db key' do
      secondary # create it before mocking GeoNode#secret_access_key

      allow_any_instance_of(GeoNode).to receive(:secret_access_key).and_raise(OpenSSL::Cipher::CipherError)

      status = subject.call(secondary)

      expect(status.health).to eq('Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.')
    end
  end
end
