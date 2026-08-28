# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceChunks::Fog, feature_category: :continuous_integration do
  let(:data_store) { described_class.new }
  let(:bucket) { 'artifacts' }
  let(:connection_params) { Gitlab.config.artifacts.object_store.connection.symbolize_keys }
  let(:connection) { ::Fog::Storage.new(connection_params) }

  before do
    stub_object_storage(connection_params: connection_params, remote_directory: bucket)
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
        expect(data_store.data(model)).to be_nil
      end
    end
  end

  describe '#set_data' do
    let(:new_data) { 'abc123' }

    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :fog_with_data, initial_data: 'sample data in fog') }

      it 'overwrites data' do
        expect(data_store.data(model)).to eq('sample data in fog')

        data_store.set_data(model, new_data)

        expect(data_store.data(model)).to eq new_data
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :fog_without_data) }

      it 'sets new data' do
        expect(data_store.data(model)).to be_nil

        data_store.set_data(model, new_data)

        expect(data_store.data(model)).to eq new_data
      end

      context 'when using an S3 provider' do
        it 'creates a file with content_type application/octet-stream' do
          expect_next_instance_of(Fog::AWS::Storage::Files) do |files|
            expect(files).to receive(:create).with(
              hash_including(
                key: anything,
                body: new_data,
                content_type: 'application/octet-stream')
            ).and_call_original
          end

          data_store.set_data(model, new_data)
        end

        context 'when fog_attributes already includes a content_type' do
          it 'preserves the content_type from fog_attributes' do
            config = instance_double(ObjectStorage::Config,
              fog_attributes: { content_type: 'application/zip' },
              aws?: true)
            allow(data_store).to receive(:object_store_config).and_return(config)

            attrs = data_store.send(:create_attributes, model, new_data)

            expect(attrs[:content_type]).to eq('application/zip')
          end
        end
      end

      context 'when using a non-S3 provider' do
        it 'does not set a default content_type' do
          config = instance_double(ObjectStorage::Config,
            fog_attributes: {},
            aws?: false)
          allow(data_store).to receive(:object_store_config).and_return(config)

          attrs = data_store.send(:create_attributes, model, new_data)

          expect(attrs).not_to have_key(:content_type)
        end
      end

      context 'when S3 server side encryption is enabled' do
        before do
          config = Gitlab.config.artifacts.object_store.to_h
          config[:storage_options] = { server_side_encryption: 'AES256' }
          allow(data_store).to receive(:object_store_raw_config).and_return(config)
        end

        it 'creates a file with attributes' do
          expect_next_instance_of(Fog::AWS::Storage::Files) do |files|
            expect(files).to receive(:create).with(
              hash_including(
                key: anything,
                body: new_data,
                content_type: 'application/octet-stream',
                'x-amz-server-side-encryption' => 'AES256')
            ).and_call_original
          end

          expect(data_store.data(model)).to be_nil

          data_store.set_data(model, new_data)

          expect(data_store.data(model)).to eq new_data
        end
      end
    end
  end

  describe '#append_data' do
    let(:initial_data) { (+'😺').force_encoding(Encoding::ASCII_8BIT) }
    let(:model) { create(:ci_build_trace_chunk, :fog_with_data, initial_data: initial_data) }
    let(:data) { data_store.data(model) }

    it 'appends ASCII data' do
      data_store.append_data(model, +'hello world', 4)

      expect(data.encoding).to eq(Encoding::ASCII_8BIT)
      expect(data.force_encoding(Encoding::UTF_8)).to eq('😺hello world')
    end

    it 'appends UTF-8 data' do
      data_store.append_data(model, +'Résumé', 4)

      expect(data.encoding).to eq(Encoding::ASCII_8BIT)
      expect(data.force_encoding(Encoding::UTF_8)).to eq("😺Résumé")
    end

    context 'when initial data is UTF-8' do
      let(:initial_data) { +'😺' }

      it 'appends ASCII data' do
        data_store.append_data(model, +'hello world', 4)

        expect(data.encoding).to eq(Encoding::ASCII_8BIT)
        expect(data.force_encoding(Encoding::UTF_8)).to eq('😺hello world')
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

        expect(data_store.data(model)).to be_nil
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :fog_without_data) }

      it 'does nothing' do
        expect(data_store.data(model)).to be_nil

        subject

        expect(data_store.data(model)).to be_nil
      end
    end
  end

  describe '#size' do
    context 'when data exists' do
      let(:model) { create(:ci_build_trace_chunk, :fog_with_data, initial_data: 'üabcd') }

      it 'returns data bytesize correctly' do
        expect(data_store.size(model)).to eq 6
      end
    end

    context 'when data does not exist' do
      let(:model) { create(:ci_build_trace_chunk, :fog_without_data) }

      it 'returns zero' do
        expect(data_store.size(model)).to be_zero
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

  describe '#connection' do
    context 'when the connection cache feature flag is enabled' do
      it 'reuses a single connection across data store instances' do
        first = described_class.new.send(:connection)
        second = described_class.new.send(:connection)

        expect(first).not_to be_nil
        expect(second).to equal(first)
        expect(described_class.connections.size).to eq(1)
      end

      it 'builds the Fog connection only once' do
        expect(::Fog::Storage).to receive(:new).once.and_call_original

        3.times { described_class.new.send(:connection) }
      end

      it 'caches a distinct connection per credentials set and reuses it per set' do
        conn_a = connection_with(connection_params.merge(aws_access_key_id: 'key-a'))
        conn_b = connection_with(connection_params.merge(aws_access_key_id: 'key-b'))

        expect(conn_b).not_to equal(conn_a)
        expect(described_class.connections.size).to eq(2)

        # The same credentials return the originally cached connection.
        expect(connection_with(connection_params.merge(aws_access_key_id: 'key-a'))).to equal(conn_a)
        expect(described_class.connections.size).to eq(2)
      end

      def connection_with(credentials)
        object_store = double(connection: double(to_hash: credentials)) # rubocop:disable RSpec/VerifiedDoubles -- lightweight config stub
        config = instance_double(ObjectStorage::Config, use_iam_profile?: false)
        described_class.new.tap do |store|
          allow(store).to receive_messages(object_store: object_store, object_store_config: config)
        end.send(:connection)
      end
    end

    context 'when the connection cache feature flag is disabled' do
      before do
        stub_feature_flags(cache_ci_build_trace_chunk_fog_connection: false)
      end

      it 'does not populate the process-level cache' do
        expect(data_store.send(:connection)).not_to be_nil
        expect(described_class.connections).to be_empty
      end
    end

    context 'when the connection uses an IAM instance profile' do
      before do
        allow_next_instance_of(ObjectStorage::Config) do |config|
          allow(config).to receive(:use_iam_profile?).and_return(true)
        end
      end

      it 'does not use the process-level cache to avoid the fog-aws credential refresh race' do
        expect(data_store.send(:connection)).not_to be_nil
        expect(described_class.connections).to be_empty
      end
    end

    context 'when object storage is disabled' do
      before do
        stub_artifacts_object_storage(enabled: false)
      end

      it 'returns nil' do
        expect(data_store.send(:connection)).to be_nil
      end
    end
  end
end
