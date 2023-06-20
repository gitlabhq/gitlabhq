# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::SecureFiles::MigrationHelper, feature_category: :mobile_devops do
  before do
    stub_ci_secure_file_object_storage
  end

  describe '.migrate_to_remote_storage' do
    let!(:local_file) { create(:ci_secure_file) }

    subject { described_class.migrate_to_remote_storage }

    it 'migrates remote files to remote storage' do
      subject

      expect(local_file.reload.file_store).to eq(Ci::SecureFileUploader::Store::REMOTE)
    end
  end

  describe '.migrate_in_batches' do
    let!(:local_file) { create(:ci_secure_file) }
    let!(:storage) { Ci::SecureFileUploader::Store::REMOTE }

    subject { described_class.migrate_to_remote_storage }

    it 'migrates the given file to the given storage backend' do
      expect_next_found_instance_of(Ci::SecureFile) do |instance|
        expect(instance).to receive_message_chain(:file, :migrate!).with(storage)
      end

      described_class.send(:migrate_in_batches, Ci::SecureFile.all, storage)
    end

    it 'calls the given block for each migrated file' do
      expect_next_found_instance_of(Ci::SecureFile) do |instance|
        expect(instance).to receive(:metadata)
      end

      described_class.send(:migrate_in_batches, Ci::SecureFile.all, storage, &:metadata)
    end
  end
end
