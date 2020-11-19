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

      context 'and a version exists (migration to versioned in progress)' do
        let!(:migrated_version) { create(:terraform_state_version, terraform_state: terraform_state) }

        it { is_expected.to eq terraform_state.latest_version.file }
      end
    end
  end

  describe '#update_file!' do
    let_it_be(:build) { create(:ci_build) }
    let_it_be(:version) { 3 }
    let_it_be(:data) { Hash[terraform_version: '0.12.21'].to_json }

    subject { terraform_state.update_file!(CarrierWaveStringFile.new(data), version: version, build: build) }

    context 'versioning is enabled' do
      let(:terraform_state) { create(:terraform_state) }

      it 'creates a new version' do
        expect { subject }.to change { Terraform::StateVersion.count }

        expect(terraform_state.latest_version.version).to eq(version)
        expect(terraform_state.latest_version.build).to eq(build)
        expect(terraform_state.latest_version.file.read).to eq(data)
      end
    end

    context 'versioning is disabled' do
      let(:terraform_state) { create(:terraform_state, :with_file) }

      it 'modifies the existing state record' do
        expect { subject }.not_to change { Terraform::StateVersion.count }

        expect(terraform_state.latest_file.read).to eq(data)
      end

      context 'and a version exists (migration to versioned in progress)' do
        let!(:migrated_version) { create(:terraform_state_version, terraform_state: terraform_state, version: 0) }

        it 'creates a new version, corrects the migrated version number, and marks the state as versioned' do
          expect { subject }.to change { Terraform::StateVersion.count }

          expect(migrated_version.reload.version).to eq(1)
          expect(migrated_version.file.read).to eq(terraform_state_file)

          expect(terraform_state.reload.latest_version.version).to eq(version)
          expect(terraform_state.latest_version.file.read).to eq(data)
          expect(terraform_state).to be_versioning_enabled
        end

        context 'the current version cannot be determined' do
          before do
            migrated_version.update!(file: CarrierWaveStringFile.new('invalid-json'))
          end

          it 'uses version - 1 to correct the migrated version number' do
            expect { subject }.to change { Terraform::StateVersion.count }

            expect(migrated_version.reload.version).to eq(2)
          end
        end
      end
    end
  end
end
