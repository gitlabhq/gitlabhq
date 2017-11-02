require 'spec_helper'

describe Geo::NodeStatusService do
  set(:primary)   { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  subject { described_class.new }

  describe '#status_keys' do
    it 'matches the serializer keys' do
      exceptions = %w[
        id
        healthy
        repositories_synced_in_percentage
        lfs_objects_synced_in_percentage
        attachments_synced_in_percentage
      ]

      expected = GeoNodeStatusEntity
        .new(GeoNodeStatus.new)
        .as_json
        .keys
        .map(&:to_s) - exceptions

      expect(subject.status_keys).to match_array(expected)
    end
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
               db_replication_lag_seconds: 0,
               repositories_count: 10,
               repositories_synced_count: 1,
               repositories_failed_count: 2,
               lfs_objects_count: 100,
               lfs_objects_synced_count: 50,
               lfs_objects_failed_count: 12,
               attachments_count: 30,
               attachments_synced_count: 30,
               attachments_failed_count: 25,
               last_event_id: 2,
               last_event_timestamp: Time.now.to_i,
               cursor_last_event_id: 1,
               cursor_last_event_timestamp: Time.now.to_i }
      request = double(success?: true, parsed_response: data.stringify_keys, code: 200)
      allow(described_class).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status).to have_attributes(data)
      expect(status.success).to be true
    end

    it 'omits full response text in status' do
      request = double(success?: false,
                       code: 401,
                       message: 'Unauthorized',
                       parsed_response: '<html><h1>You are not allowed</h1></html>')
      allow(described_class).to receive(:get).and_return(request)

      status = subject.call(secondary)

      expect(status.health).to eq("Could not connect to Geo node - HTTP Status Code: 401 Unauthorized\n")
      expect(status.success).to be false
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
      allow_any_instance_of(GeoNode).to receive(:secret_access_key).and_raise(OpenSSL::Cipher::CipherError)

      status = subject.call(secondary)

      expect(status.health).to eq('Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.')
    end

    it 'gracefully handles case when primary is deleted' do
      primary.destroy!

      status = subject.call(secondary)

      expect(status.health).to eq('This GitLab instance does not appear to be configured properly as a Geo node. Make sure the URLs are using the correct fully-qualified domain names.')
    end
  end
end
