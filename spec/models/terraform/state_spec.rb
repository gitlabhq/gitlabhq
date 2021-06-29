# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::State do
  subject { create(:terraform_state, :with_version) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:locked_by_user).class_name('User') }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:project_id) }

  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }

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

    describe '.with_name' do
      let_it_be(:matching_name) { create(:terraform_state, name: 'matching-name') }
      let_it_be(:other_name) { create(:terraform_state, name: 'other-name') }

      subject { described_class.with_name(matching_name.name) }

      it { is_expected.to contain_exactly(matching_name) }
    end
  end

  describe '#destroy' do
    let(:terraform_state) { create(:terraform_state) }
    let(:user) { terraform_state.project.creator }

    it 'deletes when the state is unlocked' do
      expect(terraform_state.destroy).to be_truthy
    end

    it 'fails to delete when the state is locked', :aggregate_failures do
      terraform_state.update!(lock_xid: SecureRandom.uuid, locked_by_user: user, locked_at: Time.current)

      expect(terraform_state.destroy).to be_falsey
      expect(terraform_state.errors.full_messages).to eq(["You cannot remove the State file because it's locked. Unlock the State file first before removing it."])
    end
  end

  describe '#latest_file' do
    let(:terraform_state) { create(:terraform_state, :with_version) }
    let(:latest_version) { terraform_state.latest_version }

    subject { terraform_state.latest_file }

    it { is_expected.to eq latest_version.file }

    context 'but no version exists yet' do
      let(:terraform_state) { create(:terraform_state) }

      it { is_expected.to be_nil }
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

    context 'versioning is disabled (migration to versioned in progress)' do
      let(:terraform_state) { create(:terraform_state, versioning_enabled: false) }
      let!(:migrated_version) { create(:terraform_state_version, terraform_state: terraform_state, version: 0) }

      it 'creates a new version, corrects the migrated version number, and marks the state as versioned' do
        expect { subject }.to change { Terraform::StateVersion.count }

        expect(migrated_version.reload.version).to eq(1)
        expect(migrated_version.file.read).to eq(fixture_file('terraform/terraform.tfstate'))

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
