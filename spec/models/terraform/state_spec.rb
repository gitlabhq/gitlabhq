# frozen_string_literal: true

require 'spec_helper'

describe Terraform::State do
  subject { create(:terraform_state, :with_file) }

  it { is_expected.to belong_to(:project) }

  it { is_expected.to validate_presence_of(:project_id) }

  before do
    stub_terraform_state_object_storage(Terraform::StateUploader)
  end

  describe '#file_store' do
    context 'when no value is set' do
      it 'returns the default store of the uploader' do
        [ObjectStorage::Store::LOCAL, ObjectStorage::Store::REMOTE].each do |store|
          expect(Terraform::StateUploader).to receive(:default_store).and_return(store)
          expect(described_class.new.file_store).to eq(store)
        end
      end
    end

    context 'when a value is set' do
      it 'returns the value' do
        [ObjectStorage::Store::LOCAL, ObjectStorage::Store::REMOTE].each do |store|
          expect(build(:terraform_state, file_store: store).file_store).to eq(store)
        end
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
        stub_terraform_state_object_storage(Terraform::StateUploader, enabled: false)
      end

      it 'sets file_store to local' do
        expect(subject.file_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end
  end
end
