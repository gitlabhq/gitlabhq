# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateUploader, feature_category: :deployment_management do
  subject { state_version.file }

  let(:state_version) { create(:terraform_state_version) }

  before do
    stub_terraform_state_object_storage
  end

  describe '.workhorse_local_upload_path' do
    let(:expected_dir) { Rails.root.join('public/uploads/tmp/terraform_state').to_s }

    it 'returns a directory based on public/uploads/tmp' do
      expect(described_class.workhorse_local_upload_path).to eq(expected_dir)
    end
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
    context 'when terraform state encryption is enabled in application setting' do
      before do
        allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
        stub_application_setting(terraform_state_encryption_enabled: true)
      end

      context 'when skip_encrypting_terraform_state_file feature flag is enabled' do
        before do
          stub_feature_flags(skip_encrypting_terraform_state_file: true)
        end

        it 'encrypts the stored file' do
          expect(subject.file.read).not_to eq(fixture_file('terraform/terraform.tfstate'))
        end
      end

      context 'when skip_encrypting_terraform_state_file feature flag is disabled' do
        before do
          stub_feature_flags(skip_encrypting_terraform_state_file: false)
        end

        it 'encrypts the stored file' do
          expect(subject.file.read).not_to eq(fixture_file('terraform/terraform.tfstate'))
        end
      end
    end

    context 'when terraform state encryption is disabled in application setting' do
      before do
        allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
        stub_application_setting(terraform_state_encryption_enabled: false)
      end

      context 'when skip_encrypting_terraform_state_file feature flag is enabled' do
        before do
          stub_feature_flags(skip_encrypting_terraform_state_file: true)
        end

        it 'does not encrypt the stored file' do
          expect(subject.file.read).to eq(fixture_file('terraform/terraform.tfstate'))
        end
      end

      context 'when skip_encrypting_terraform_state_file feature flag is disabled' do
        before do
          stub_feature_flags(skip_encrypting_terraform_state_file: false)
        end

        it 'encrypts the stored file' do
          expect(subject.file.read).not_to eq(fixture_file('terraform/terraform.tfstate'))
        end
      end
    end
  end

  describe 'decryption' do
    context 'when the file is not encrypted' do
      before do
        allow(state_version).to receive(:is_encrypted?).and_return(false)
      end

      it 'reads the file without decrypting' do
        expect(subject.read).not_to eq(fixture_file('terraform/terraform.tfstate'))
      end
    end

    context 'when the file is encrypted' do
      before do
        allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
        stub_application_setting(terraform_state_encryption_enabled: true)
        allow(state_version).to receive(:is_encrypted?).and_return(true)
      end

      it 'decrypts the file when reading' do
        expect(subject.read).to eq(fixture_file('terraform/terraform.tfstate'))
      end
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
