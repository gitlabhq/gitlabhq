# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CarrierWave::Storage::Fog::File', feature_category: :shared do
  let(:uploader_class) { Class.new(CarrierWave::Uploader::Base) }
  let(:uploader) { uploader_class.new }
  let(:storage) { CarrierWave::Storage::Fog.new(uploader) }
  let(:bucket_name) { 'some-bucket' }
  let(:connection) { ::Fog::Storage.new(connection_options) }
  let(:bucket) { connection.directories.new(key: bucket_name) }
  let(:test_filename) { 'test' }
  let(:test_data) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }

  subject { CarrierWave::Storage::Fog::File.new(uploader, storage, test_filename) }

  before do
    stub_object_storage(connection_params: connection_options, remote_directory: bucket_name)

    allow(uploader).to receive(:fog_directory).and_return(bucket_name)
    allow(uploader).to receive(:fog_credentials).and_return(connection_options)

    bucket.files.create(key: test_filename, body: test_data) # rubocop:disable Rails/SaveBang
  end

  context 'AWS' do
    let(:connection_options) do
      {
        provider: 'AWS',
        aws_access_key_id: 'AWS_ACCESS_KEY',
        aws_secret_access_key: 'AWS_SECRET_KEY'
      }
    end

    describe '#copy_to' do
      let(:dest_filename) { 'copied.txt' }

      it 'copies the file' do
        fog_file = subject.send(:file)

        expect(fog_file).to receive(:concurrency=).with(10).and_call_original
        # multipart_chunk_size must be explicitly set in order to leverage
        # multithreaded, multipart transfers for files below 5GB.
        expect(fog_file).to receive(:multipart_chunk_size=).with(10.megabytes).and_call_original
        expect(fog_file).to receive(:copy).with(bucket_name, dest_filename, anything).and_call_original

        result = subject.copy_to(dest_filename)

        expect(result.exists?).to be true
        expect(result.read).to eq(test_data)

        # Sanity check that the file actually is there
        copied = bucket.files.get(dest_filename)
        expect(copied).to be_present
        expect(copied.body).to eq(test_data)
      end
    end
  end

  context 'Azure' do
    let(:connection_options) do
      {
        provider: 'AzureRM',
        azure_storage_account_name: 'AZURE_ACCOUNT_NAME',
        azure_storage_access_key: 'AZURE_ACCESS_KEY'
      }
    end

    describe '#copy_to' do
      let(:dest_filename) { 'copied.txt' }

      it 'copies the file' do
        result = subject.copy_to(dest_filename)

        # Fog Azure provider doesn't mock the actual copied data
        expect(result.exists?).to be true
      end
    end

    describe '#authenticated_url' do
      let(:expire_at) { 24.hours.from_now }
      let(:options) { { expire_at: expire_at } }

      it 'has an authenticated URL' do
        expect(subject.authenticated_url(options)).to eq("https://mockaccount.blob.core.windows.net/test_container/test_blob?token")
      end

      context 'with custom expire_at' do
        it 'properly sets expires param' do
          expect_next_instance_of(Fog::AzureRM::Storage::File) do |file|
            expect(file).to receive(:url).with(expire_at, options).and_call_original
          end

          expect(subject.authenticated_url(options)).to eq("https://mockaccount.blob.core.windows.net/test_container/test_blob?token")
        end
      end

      context 'with content_disposition option' do
        let(:options) { { expire_at: expire_at, content_disposition: 'attachment' } }

        it 'passes options' do
          expect_next_instance_of(Fog::AzureRM::Storage::File) do |file|
            expect(file).to receive(:url).with(expire_at, options).and_call_original
          end

          expect(subject.authenticated_url(options)).to eq("https://mockaccount.blob.core.windows.net/test_container/test_blob?token")
        end
      end
    end
  end
end
