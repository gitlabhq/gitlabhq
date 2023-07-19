# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Cleanup::RemoteUploads do
  context 'when object_storage is enabled' do
    let(:connection) { double }
    let(:directory) { double }
    let!(:uploads) do
      [
        create(:upload, path: 'dir/file1', store: ObjectStorage::Store::REMOTE),
        create(:upload, path: 'dir/file2', store: ObjectStorage::Store::LOCAL)
      ]
    end

    let(:remote_files) do
      [
        double(key: 'dir/file1'),
        double(key: 'dir/file2'),
        double(key: 'dir/file3'),
        double(key: 'lost_and_found/dir/file3')
      ]
    end

    before do
      stub_uploads_object_storage(FileUploader)

      expect(::Fog::Storage).to receive(:new).and_return(connection)

      expect(connection).to receive(:directories).and_return(double(new: directory))
      expect(directory).to receive(:files).and_return(remote_files)
    end

    context 'when dry_run is set to false' do
      subject { described_class.new.run!(dry_run: false) }

      it 'moves files that are not in uploads table' do
        expect(remote_files[0]).not_to receive(:copy)
        expect(remote_files[0]).not_to receive(:destroy)
        expect(remote_files[1]).to receive(:copy)
        expect(remote_files[1]).to receive(:destroy)
        expect(remote_files[2]).to receive(:copy)
        expect(remote_files[2]).to receive(:destroy)
        expect(remote_files[3]).not_to receive(:copy)
        expect(remote_files[3]).not_to receive(:destroy)

        subject
      end
    end

    context 'when dry_run is set to true' do
      subject { described_class.new.run!(dry_run: true) }

      it 'does not move filese' do
        expect(remote_files[0]).not_to receive(:copy)
        expect(remote_files[0]).not_to receive(:destroy)
        expect(remote_files[1]).not_to receive(:copy)
        expect(remote_files[1]).not_to receive(:destroy)
        expect(remote_files[2]).not_to receive(:copy)
        expect(remote_files[2]).not_to receive(:destroy)
        expect(remote_files[3]).not_to receive(:copy)
        expect(remote_files[3]).not_to receive(:destroy)

        subject
      end
    end
  end

  context 'when object_storage is not enabled' do
    it 'does not connect to any storage' do
      expect(::Fog::Storage).not_to receive(:new)

      subject
    end
  end

  context 'when a bucket prefix is configured' do
    let(:bucket_prefix) { 'test-prefix' }
    let(:credentials) do
      {
        provider: "AWS",
        aws_access_key_id: "AWS_ACCESS_KEY_ID",
        aws_secret_access_key: "AWS_SECRET_ACCESS_KEY",
        region: "eu-central-1"
      }
    end

    let(:config) { { connection: credentials, bucket_prefix: bucket_prefix, remote_directory: 'uploads' } }

    subject { described_class.new.run!(dry_run: false) }

    before do
      stub_uploads_object_storage(FileUploader, config: config)
    end

    it 'does not connect to any storage' do
      expect(::Fog::Storage).not_to receive(:new)

      expect { subject }.to raise_error(/prefixes are not supported/)
    end
  end
end
