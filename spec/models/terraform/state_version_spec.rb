# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateVersion do
  it { is_expected.to be_a FileStoreMounter }

  it { is_expected.to belong_to(:terraform_state).required }
  it { is_expected.to belong_to(:created_by_user).class_name('User').optional }
  it { is_expected.to belong_to(:build).class_name('Ci::Build').optional }

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
end
