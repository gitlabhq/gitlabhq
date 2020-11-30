# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceChunks::Fog do
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
                'x-amz-server-side-encryption' => 'AES256')
            ).and_call_original
          end

          expect(data_store.data(model)).to be_nil

          data_store.set_data(model, new_data)

          expect(data_store.data(model)).to eq new_data
        end

        context 'when ci_live_trace_use_fog_attributes flag is disabled' do
          before do
            stub_feature_flags(ci_live_trace_use_fog_attributes: false)
          end

          it 'does not pass along Fog attributes' do
            expect_next_instance_of(Fog::AWS::Storage::Files) do |files|
              expect(files).to receive(:create).with(
                key: anything,
                body: new_data
              ).and_call_original
            end

            expect(data_store.data(model)).to be_nil

            data_store.set_data(model, new_data)

            expect(data_store.data(model)).to eq new_data
          end
        end
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
      files = connection.directories.new(key: bucket).files

      expect(files.count).to eq(2)
      expect(files[0].body).to be_present
      expect(files[1].body).to be_present

      subject

      files.reload

      expect(files.count).to eq(0)
    end
  end
end
