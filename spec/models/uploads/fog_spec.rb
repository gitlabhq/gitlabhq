# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploads::Fog do
  let(:credentials) do
    {
      provider: "AWS",
      aws_access_key_id: "AWS_ACCESS_KEY_ID",
      aws_secret_access_key: "AWS_SECRET_ACCESS_KEY",
      region: "eu-central-1"
    }
  end

  let(:bucket_prefix) { nil }
  let(:data_store) { described_class.new }
  let(:config) { { connection: credentials, bucket_prefix: bucket_prefix, remote_directory: 'uploads' } }

  before do
    stub_uploads_object_storage(FileUploader, config: config)
  end

  describe '#available?' do
    subject { data_store.available? }

    context 'when object storage is enabled' do
      it { is_expected.to be_truthy }
    end

    context 'when object storage is disabled' do
      before do
        stub_uploads_object_storage(FileUploader, config: config, enabled: false)
      end

      it { is_expected.to be_falsy }
    end
  end

  context 'model with uploads' do
    let(:project) { create(:project) }
    let(:relation) { project.uploads }
    let(:connection) { ::Fog::Storage.new(credentials) }
    let(:paths) { relation.pluck(:path) }

    # Only fog-aws simulates mocking of deleting an object properly.
    # We'll just test that the various providers implement the require methods.
    describe 'Fog provider acceptance tests' do
      let!(:uploads) { create_list(:upload, 2, :with_file, :issuable_upload, model: project) }

      shared_examples 'Fog provider' do
        describe '#get_object' do
          it 'returns a Hash with a body' do
            expect(connection.get_object('uploads', paths.first)[:body]).not_to be_nil
          end
        end

        describe '#delete_object' do
          it 'returns true' do
            expect(connection.delete_object('uploads', paths.first)).to be_truthy
          end
        end
      end

      before do
        uploads.each { |upload| upload.retrieve_uploader.migrate!(2) }
      end

      context 'with AWS provider' do
        it_behaves_like 'Fog provider'
      end

      context 'with Google provider' do
        let(:credentials) do
          {
            provider: "Google",
            google_storage_access_key_id: 'ACCESS_KEY_ID',
            google_storage_secret_access_key: 'SECRET_ACCESS_KEY'
          }
        end

        it_behaves_like 'Fog provider'
      end

      context 'with AzureRM provider' do
        let(:credentials) do
          {
            provider: 'AzureRM',
            azure_storage_account_name: 'test-access-id',
            azure_storage_access_key: 'secret'
          }
        end

        it_behaves_like 'Fog provider'
      end
    end

    describe '#keys' do
      let!(:uploads) { create_list(:upload, 2, :object_storage, uploader: FileUploader, model: project) }

      subject { data_store.keys(relation) }

      it 'returns keys' do
        is_expected.to match_array(relation.pluck(:path))
      end
    end

    describe '#delete_keys' do
      let(:connection) { ::Fog::Storage.new(credentials) }
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

      context 'with bucket prefix' do
        let(:bucket_prefix) { 'test-prefix' }

        it 'deletes multiple data' do
          paths.each do |path|
            expect(connection.get_object('uploads', File.join(bucket_prefix, path))[:body]).not_to be_nil
          end

          subject

          paths.each do |path|
            expect { connection.get_object('uploads', File.join(bucket_prefix, path))[:body] }.to raise_error(Excon::Error::NotFound)
          end
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
