# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateVersion, feature_category: :infrastructure_as_code do
  it { is_expected.to be_a FileStoreMounter }
  it { is_expected.to be_a EachBatch }

  it { is_expected.to belong_to(:terraform_state).required.touch }
  it { is_expected.to belong_to(:created_by_user).class_name('User').optional }
  it { is_expected.to belong_to(:build).class_name('Ci::Build').optional }

  it_behaves_like 'object storable' do
    let(:locally_stored) do
      terraform_state_version = create(:terraform_state_version)

      if terraform_state_version.file_store == ObjectStorage::Store::REMOTE
        terraform_state_version.update_column(described_class::STORE_COLUMN, ObjectStorage::Store::LOCAL)
      end

      terraform_state_version
    end

    let(:remotely_stored) do
      terraform_state_version = create(:terraform_state_version)

      if terraform_state_version.file_store == ObjectStorage::Store::LOCAL
        terraform_state_version.update_column(described_class::STORE_COLUMN, ObjectStorage::Store::REMOTE)
      end

      terraform_state_version
    end
  end

  describe 'default attributes' do
    before do
      allow(Terraform::StateUploader).to receive(:default_store).and_return(5)
    end

    it { expect(described_class.new.file_store).to eq(5) }
    it { expect(described_class.new(file_store: 3).file_store).to eq(3) }
  end

  describe 'scopes' do
    describe '.ordered_by_version_desc' do
      let(:terraform_state) { create(:terraform_state) }
      let(:versions) { [4, 2, 5, 1, 3] }

      subject { described_class.ordered_by_version_desc }

      before do
        versions.each do |version|
          create(:terraform_state_version, terraform_state: terraform_state, version: version)
        end
      end

      it { expect(subject.map(&:version)).to eq(versions.sort.reverse) }
    end
  end

  context 'file storage' do
    subject { create(:terraform_state_version) }

    before do
      stub_terraform_state_object_storage
    end

    describe '#file' do
      let(:terraform_state_file) { fixture_file('terraform/terraform.tfstate') }

      before do
        subject.file = CarrierWaveStringFile.new(terraform_state_file)
        subject.save!
      end

      it 'returns the saved file' do
        expect(subject.file.read).to eq(terraform_state_file)
      end
    end

    describe '#file_store' do
      it 'returns the value' do
        [ObjectStorage::Store::LOCAL, ObjectStorage::Store::REMOTE].each do |store|
          subject.update!(file_store: store)

          expect(subject.file_store).to eq(store)
        end
      end
    end

    describe '#update_file_store' do
      context 'when file is stored in object storage' do
        it 'sets file_store to remote' do
          expect(subject.file_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end

      context 'when file is stored locally' do
        before do
          stub_terraform_state_object_storage(enabled: false)
        end

        it 'sets file_store to local' do
          expect(subject.file_store).to eq(ObjectStorage::Store::LOCAL)
        end
      end
    end
  end

  describe '#encryption_enabled?' do
    let_it_be(:project) { create(:project) }
    let(:terraform_state) { create(:terraform_state, project: project) }
    let(:state_version) { build(:terraform_state_version, terraform_state: terraform_state) }

    before do
      allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
      stub_application_setting(terraform_state_encryption_enabled: encryption_enabled)
    end

    context 'when encryption is disabled in settings' do
      let(:encryption_enabled) { false }

      it 'returns false' do
        expect(state_version.encryption_enabled?).to be false
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(skip_encrypting_terraform_state_file: false)
        end

        it 'returns true' do
          expect(state_version.encryption_enabled?).to be true
        end
      end
    end

    context 'when encryption is enabled in settings' do
      let(:encryption_enabled) { true }

      it 'returns true' do
        expect(state_version.encryption_enabled?).to be true
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(skip_encrypting_terraform_state_file: false)
        end

        it 'returns true' do
          expect(state_version.encryption_enabled?).to be true
        end
      end
    end

    context 'when application setting is nil' do
      let(:encryption_enabled) { nil }

      it 'returns true' do
        expect(state_version.encryption_enabled?).to be true
      end
    end
  end

  describe '#set_encrypted_flag' do
    let_it_be(:project) { create(:project) }
    let(:terraform_state) { create(:terraform_state, project: project) }

    subject { build(:terraform_state_version, terraform_state: terraform_state) }

    before do
      allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
      stub_application_setting(terraform_state_encryption_enabled: encryption_enabled)
    end

    context 'when encryption is enabled' do
      let(:encryption_enabled) { true }

      it 'sets is_encrypted to true' do
        subject.save!
        expect(subject.is_encrypted).to be true
      end
    end

    context 'when encryption is disabled' do
      let(:encryption_enabled) { false }

      it 'sets is_encrypted to false' do
        subject.save!
        expect(subject.is_encrypted).to be false
      end
    end

    context 'when existing record is updated' do
      let(:encryption_enabled) { false }

      it 'does not recalculate is_encrypted' do
        subject.save!
        expect(subject.is_encrypted).to be false

        allow(ApplicationSetting).to receive(:current).and_return(
          ApplicationSetting.new(terraform_state_encryption_enabled: true)
        )

        subject.update!(version: 999)
        expect(subject.is_encrypted).to be false
      end
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:terraform_state_version) }
    let!(:parent) { model.build }
  end
end
