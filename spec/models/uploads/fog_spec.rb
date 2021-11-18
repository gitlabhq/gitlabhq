# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploads::Fog do
  let(:data_store) { described_class.new }

  before do
    stub_uploads_object_storage(FileUploader)
  end

  describe '#available?' do
    subject { data_store.available? }

    context 'when object storage is enabled' do
      it { is_expected.to be_truthy }
    end

    context 'when object storage is disabled' do
      before do
        stub_uploads_object_storage(FileUploader, enabled: false)
      end

      it { is_expected.to be_falsy }
    end
  end

  context 'model with uploads' do
    let(:project) { create(:project) }
    let(:relation) { project.uploads }

    describe '#keys' do
      let!(:uploads) { create_list(:upload, 2, :object_storage, uploader: FileUploader, model: project) }

      subject { data_store.keys(relation) }

      it 'returns keys' do
        is_expected.to match_array(relation.pluck(:path))
      end
    end

    describe '#delete_keys' do
      let(:connection) { ::Fog::Storage.new(FileUploader.object_store_credentials) }
      let(:keys) { data_store.keys(relation) }
      let(:paths) { relation.pluck(:path) }
      let!(:uploads) { create_list(:upload, 2, :with_file, :issuable_upload, model: project) }

      subject { data_store.delete_keys(keys) }

      before do
        uploads.each { |upload| upload.retrieve_uploader.migrate!(2) }
      end

      it 'deletes multiple data' do
        paths.each do |path|
          expect(connection.get_object('uploads', path)[:body]).not_to be_nil
        end

        subject

        paths.each do |path|
          expect { connection.get_object('uploads', path)[:body] }.to raise_error(Excon::Error::NotFound)
        end
      end

      context 'when one of keys is missing' do
        let(:keys) { ['unknown'] + super() }

        it 'deletes only existing keys' do
          paths.each do |path|
            expect(connection.get_object('uploads', path)[:body]).not_to be_nil
          end

          expect_next_instance_of(::Fog::Storage) do |storage|
            allow(storage).to receive(:delete_object).and_call_original
            expect(storage).to receive(:delete_object).with('uploads', keys.first).and_raise(::Google::Apis::ClientError, 'NotFound')
          end

          subject

          paths.each do |path|
            expect { connection.get_object('uploads', path)[:body] }.to raise_error(Excon::Error::NotFound)
          end
        end
      end
    end
  end
end
