# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateUploader do
  subject { state_version.file }

  let(:state_version) { create(:terraform_state_version) }

  before do
    stub_terraform_state_object_storage
  end

  describe '#filename' do
    it 'contains the version of the terraform state record' do
      expect(subject.filename).to eq("#{state_version.version}.tfstate")
    end

    context 'legacy state with versioning disabled' do
      let(:state) { create(:terraform_state, versioning_enabled: false) }
      let(:state_version) { create(:terraform_state_version, terraform_state: state) }

      it 'contains the UUID of the terraform state record' do
        expect(subject.filename).to eq("#{state_version.uuid}.tfstate")
      end
    end
  end

  describe '#store_dir' do
    it 'hashes the project ID and UUID' do
      expect(Gitlab::HashedPath).to receive(:new)
        .with(state_version.uuid, root_hash: state_version.project_id)
        .and_return(:store_dir)

      expect(subject.store_dir).to eq(:store_dir)
    end

    context 'legacy state with versioning disabled' do
      let(:state) { create(:terraform_state, versioning_enabled: false) }
      let(:state_version) { create(:terraform_state_version, terraform_state: state) }

      it 'contains the ID of the project' do
        expect(subject.store_dir).to include(state_version.project_id.to_s)
      end
    end
  end

  describe '#key' do
    it 'creates a digest with a secret key and the project id' do
      expect(OpenSSL::HMAC)
        .to receive(:digest)
        .with('SHA256', Gitlab::Application.credentials.db_key_base, state_version.project_id.to_s)
        .and_return('digest')

      expect(subject.key).to eq('digest')
    end
  end

  describe 'encryption' do
    it 'encrypts the stored file' do
      expect(subject.file.read).not_to eq(fixture_file('terraform/terraform.tfstate'))
    end

    it 'decrypts the file when reading' do
      expect(subject.read).to eq(fixture_file('terraform/terraform.tfstate'))
    end
  end

  describe '.direct_upload_enabled?' do
    it 'returns false' do
      expect(described_class.direct_upload_enabled?).to eq(false)
    end
  end

  describe '.proxy_download_enabled?' do
    it 'returns true' do
      expect(described_class.proxy_download_enabled?).to eq(true)
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
        stub_terraform_state_object_storage(enabled: false)
      end

      it 'returns LOCAL' do
        expect(described_class.default_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end
  end
end
