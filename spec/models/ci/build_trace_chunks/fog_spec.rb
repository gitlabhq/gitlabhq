require 'spec_helper'

describe Ci::BuildTraceChunks::Fog do
  let(:data_store) { described_class.new }

  before do
    stub_artifacts_object_storage
  end

  describe '#available?' do
    subject { data_store.available? }

    context 'when object storage is enabled' do
      it { is_expected.to be_truthy }
    end

    context 'when object storage is disabled' do
      before do
        stub_artifacts_object_storage(enabled: false)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#data' do
    subject { data_store.data(model) }

    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :fog_with_data, initial_data: 'sample data in fog') }

      it 'returns the data' do
        is_expected.to eq('sample data in fog')
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :fog_without_data) }

      it 'returns nil' do
        expect { data_store.data(model) }.to raise_error(Excon::Error::NotFound)
      end
    end
  end

  describe '#set_data' do
    subject { data_store.set_data(model, data) }

    let(:data) { 'abc123' }

    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :fog_with_data, initial_data: 'sample data in fog') }

      it 'overwrites data' do
        expect(data_store.data(model)).to eq('sample data in fog')

        subject

        expect(data_store.data(model)).to eq('abc123')
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :fog_without_data) }

      it 'sets new data' do
        expect { data_store.data(model) }.to raise_error(Excon::Error::NotFound)

        subject

        expect(data_store.data(model)).to eq('abc123')
      end
    end
  end

  describe '#delete_data' do
    subject { data_store.delete_data(model) }

    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :fog_with_data, initial_data: 'sample data in fog') }

      it 'deletes data' do
        expect(data_store.data(model)).to eq('sample data in fog')

        subject

        expect { data_store.data(model) }.to raise_error(Excon::Error::NotFound)
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :fog_without_data) }

      it 'does nothing' do
        expect { data_store.data(model) }.to raise_error(Excon::Error::NotFound)

        subject

        expect { data_store.data(model) }.to raise_error(Excon::Error::NotFound)
      end
    end
  end

  describe '#keys' do
    subject { data_store.keys(relation) }

    let(:build) { create(:ci_build) }
    let(:relation) { build.trace_chunks }

    before do
      create(:ci_build_trace_chunk, :fog_with_data, chunk_index: 0, build: build)
      create(:ci_build_trace_chunk, :fog_with_data, chunk_index: 1, build: build)
    end

    it 'returns keys' do
      is_expected.to eq([[build.id, 0], [build.id, 1]])
    end
  end

  describe '#delete_keys' do
    subject { data_store.delete_keys(keys) }

    let(:build) { create(:ci_build) }
    let(:relation) { build.trace_chunks }
    let(:keys) { data_store.keys(relation) }

    before do
      create(:ci_build_trace_chunk, :fog_with_data, chunk_index: 0, build: build)
      create(:ci_build_trace_chunk, :fog_with_data, chunk_index: 1, build: build)
    end

    it 'deletes multiple data' do
      ::Fog::Storage.new(JobArtifactUploader.object_store_credentials).tap do |connection|
        expect(connection.get_object('artifacts', "tmp/builds/#{build.id}/chunks/0.log")[:body]).to be_present
        expect(connection.get_object('artifacts', "tmp/builds/#{build.id}/chunks/1.log")[:body]).to be_present
      end

      subject

      ::Fog::Storage.new(JobArtifactUploader.object_store_credentials).tap do |connection|
        expect { connection.get_object('artifacts', "tmp/builds/#{build.id}/chunks/0.log")[:body] }.to raise_error(Excon::Error::NotFound)
        expect { connection.get_object('artifacts', "tmp/builds/#{build.id}/chunks/1.log")[:body] }.to raise_error(Excon::Error::NotFound)
      end
    end
  end
end
