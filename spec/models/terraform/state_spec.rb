# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::State do
  subject { create(:terraform_state, :with_file) }

  let(:terraform_state_file) { fixture_file('terraform/terraform.tfstate') }

  it { is_expected.to be_a FileStoreMounter }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:locked_by_user).class_name('User') }

  it { is_expected.to validate_presence_of(:project_id) }

  before do
    stub_terraform_state_object_storage
  end

  describe 'scopes' do
    describe '.ordered_by_name' do
      let_it_be(:project) { create(:project) }
      let(:names) { %w(state_d state_b state_a state_c) }

      subject { described_class.ordered_by_name }

      before do
        names.each do |name|
          create(:terraform_state, project: project, name: name)
        end
      end

      it { expect(subject.map(&:name)).to eq(names.sort) }
    end
  end

  describe '#file' do
    context 'when a file exists' do
      it 'does not use the default file' do
        expect(subject.file.read).to eq(terraform_state_file)
      end
    end
  end

  describe '#file_store' do
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
      it_behaves_like 'mounted file in object store'
    end

    context 'when file is stored locally' do
      before do
        stub_terraform_state_object_storage(enabled: false)
      end

      it_behaves_like 'mounted file in local store'
    end
  end

  describe '#latest_file' do
    subject { terraform_state.latest_file }

    context 'versioning is enabled' do
      let(:terraform_state) { create(:terraform_state, :with_version) }
      let(:latest_version) { terraform_state.latest_version }

      it { is_expected.to eq latest_version.file }

      context 'but no version exists yet' do
        let(:terraform_state) { create(:terraform_state) }

        it { is_expected.to be_nil }
      end
    end

    context 'versioning is disabled' do
      let(:terraform_state) { create(:terraform_state, :with_file) }

      it { is_expected.to eq terraform_state.file }
    end
  end

  describe '#update_file!' do
    let(:version) { 2 }
    let(:data) { Hash[terraform_version: '0.12.21'].to_json }

    subject { terraform_state.update_file!(CarrierWaveStringFile.new(data), version: version) }

    context 'versioning is enabled' do
      let(:terraform_state) { create(:terraform_state) }

      it 'creates a new version' do
        expect { subject }.to change { Terraform::StateVersion.count }

        expect(terraform_state.latest_version.version).to eq(version)
        expect(terraform_state.latest_version.file.read).to eq(data)
      end
    end

    context 'versioning is disabled' do
      let(:terraform_state) { create(:terraform_state, :with_file) }

      it 'modifies the existing state record' do
        expect { subject }.not_to change { Terraform::StateVersion.count }

        expect(terraform_state.latest_file.read).to eq(data)
      end
    end
  end
end
