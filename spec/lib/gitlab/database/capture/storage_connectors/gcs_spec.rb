# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Capture::StorageConnectors::Gcs, feature_category: :database do
  let(:connector) { described_class.new(settings) }
  let(:client) { instance_double(Google::Cloud::Storage::Project) }
  let(:bucket) { instance_double(Google::Cloud::Storage::Bucket) }
  let(:settings) do
    GitlabSettings::Options.build(
      provider: 'Gcs',
      project_id: 'my-project',
      credentials: '/path/to/keyfile.json',
      bucket: 'my-bucket'
    )
  end

  let(:data) do
    <<~NDJSON
      {"id": 1, "sql": "SELECT 1 FROM \"public\".\"users\" LIMIT 1;"}
      {"id": 2, "sql": "SELECT * FROM \"public\".\"projects\" WHERE \"projects\".\"id\" = 1;"}
      {"id": 3, "sql": "DELETE FROM \"public\".\"users\" WHERE \"users\".\"id\" = 1;"}
    NDJSON
  end

  before do
    allow(Google::Cloud::Storage).to receive(:new).and_return(client)
    allow(client).to receive(:bucket).and_return(bucket)
  end

  describe '#upload' do
    let(:filename) { "v1-main-cadf8f5a--1F/4BEAABE0" }
    let(:encoded_filename) { "v1-main-cadf8f5a--1F%2F4BEAABE0" }
    let(:metadata) { { original_filename: filename, encoded: true } }

    it 'uploads data to the specified bucket' do
      expect(bucket).to receive(:create_file).with(instance_of(StringIO), encoded_filename, metadata: metadata)

      connector.upload(filename, data)
    end

    context 'when upload fails' do
      let(:error) { ArgumentError.new('Upload failed') }

      before do
        allow(bucket).to receive(:create_file).and_raise(error)
      end

      it 'propagates the error' do
        expect { connector.upload(filename, data) }.to raise_error(error)
      end
    end
  end
end
