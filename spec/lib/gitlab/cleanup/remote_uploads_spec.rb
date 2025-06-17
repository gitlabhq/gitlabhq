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
      subject(:run) { described_class.new.run!(dry_run: false) }

      it 'moves files that are not in uploads table' do
        expect(remote_files[0]).not_to receive(:copy)
        expect(remote_files[0]).not_to receive(:destroy)
        expect(remote_files[1]).to receive(:copy)
        expect(remote_files[1]).to receive(:destroy)
        expect(remote_files[2]).to receive(:copy)
        expect(remote_files[2]).to receive(:destroy)
        expect(remote_files[3]).not_to receive(:copy)
        expect(remote_files[3]).not_to receive(:destroy)

        run
      end
    end

    context 'when dry_run is set to true' do
      subject(:run) { described_class.new.run!(dry_run: true) }

      it 'does not move files' do
        expect(remote_files[0]).not_to receive(:copy)
        expect(remote_files[0]).not_to receive(:destroy)
        expect(remote_files[1]).not_to receive(:copy)
        expect(remote_files[1]).not_to receive(:destroy)
        expect(remote_files[2]).not_to receive(:copy)
        expect(remote_files[2]).not_to receive(:destroy)
        expect(remote_files[3]).not_to receive(:copy)
        expect(remote_files[3]).not_to receive(:destroy)

        run
      end
    end

    it 'logs tracked and untracked paths' do
      logger = Logger.new(nil)

      expect(logger).to receive(:info).once.with(
        "Looking for orphaned remote uploads files to move to lost and found. Dry run...")
      expect(logger).to receive(:debug).once.with(hash_including(
        message: "Found DB record for remote stored file", file_path: "dir/file1", is_tracked: true))
      expect(logger).to receive(:info).once.with(hash_including(
        message: "Did not find DB record for remote stored file", file_path: "dir/file2", is_tracked: false))
      expect(logger).to receive(:info).once.with(hash_including(
        message: "Did not find DB record for remote stored file", file_path: "dir/file3", is_tracked: false))

      described_class.new(logger: logger).run!
    end
  end

  context 'when object_storage is not enabled' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:object_store).and_return(double(enabled: false))
      end
    end

    it 'does not connect to any storage' do
      expect(::Fog::Storage).not_to receive(:new)

      described_class.new.run!
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

    subject(:run) { described_class.new.run!(dry_run: false) }

    before do
      stub_uploads_object_storage(FileUploader, config: config)

      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:bucket_prefix).and_return(bucket_prefix)
      end
    end

    it 'does not connect to any storage and logs error' do
      expect(::Fog::Storage).not_to receive(:new)
      expect(Gitlab::AppLogger).to receive(:error)

      run
    end
  end
end
