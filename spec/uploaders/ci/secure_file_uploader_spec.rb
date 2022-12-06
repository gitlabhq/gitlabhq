# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SecureFileUploader do
  subject { ci_secure_file.file }

  let(:project) { create(:project) }
  let(:ci_secure_file) { create(:ci_secure_file) }
  let(:sample_file) { fixture_file('ci_secure_files/upload-keystore.jks') }

  before do
    stub_ci_secure_file_object_storage
  end

  describe '#key' do
    it 'creates a digest with a secret key and the project id' do
      expect(Digest::SHA256)
        .to receive(:digest)
        .with(ci_secure_file.key_data)
        .and_return('digest')

      expect(subject.key).to eq('digest')
    end
  end

  describe '.checksum' do
    it 'returns a SHA256 checksum for the unencrypted file' do
      expect(subject.checksum).to eq(Digest::SHA256.hexdigest(sample_file))
    end
  end

  describe 'encryption' do
    it 'encrypts the stored file' do
      expect(Base64.encode64(subject.file.read)).not_to eq(Base64.encode64(sample_file))
    end

    it 'decrypts the file when reading' do
      expect(Base64.encode64(subject.read)).to eq(Base64.encode64(sample_file))
    end
  end

  describe '.direct_upload_enabled?' do
    it 'returns false' do
      expect(described_class.direct_upload_enabled?).to eq(false)
    end
  end

  describe '.default_store' do
    context 'when object storage is enabled' do
      it 'returns REMOTE' do
        expect(described_class.default_store).to eq(ObjectStorage::Store::REMOTE)
      end
    end

    context 'when object storage is disabled' do
      before do
        stub_ci_secure_file_object_storage(enabled: false)
      end

      it 'returns LOCAL' do
        expect(described_class.default_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end
  end
end
