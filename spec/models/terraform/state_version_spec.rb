# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateVersion, feature_category: :infrastructure_as_code do
  it { is_expected.to be_a FileStoreMounter }
  it { is_expected.to be_a EachBatch }

  it { is_expected.to belong_to(:terraform_state).required.touch }
  it { is_expected.to belong_to(:created_by_user).class_name('User').optional }
  it { is_expected.to belong_to(:build).class_name('Ci::Build').optional }

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

    describe '.with_files_stored_locally' do
      subject { described_class.with_files_stored_locally }

      it 'includes states with local storage' do
        create_list(:terraform_state_version, 5)

        expect(subject).to have_attributes(count: 5)
      end

      it 'excludes states without local storage' do
        stub_terraform_state_object_storage

        create_list(:terraform_state_version, 5)

        expect(subject).to have_attributes(count: 0)
      end
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

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:terraform_state_version) }
    let!(:parent) { model.build }
  end
end
