# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::State, feature_category: :infrastructure_as_code do
  subject { create(:terraform_state, :with_version) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:locked_by_user).class_name('User').optional }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_presence_of(:uuid) }

  describe 'default values' do
    it { expect(described_class.new.uuid).to be_present }
    it { expect(described_class.new(uuid: 'test').uuid).to eq('test') }
  end

  describe 'scopes' do
    describe '.ordered_by_name' do
      let_it_be(:project) { create(:project) }

      let(:names) { %w[state_d state_b state_a state_c] }

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

    describe '.ready_for_destruction' do
      let_it_be(:not_deleted) { create(:terraform_state) }

      let_it_be(:within_grace_period) do
        create(:terraform_state, deleted_at: (described_class::GRACE_PERIOD - 1.minute).ago)
      end

      let(:exactly_at_grace_boundary) do
        create(:terraform_state, deleted_at: described_class::GRACE_PERIOD.ago)
      end

      let_it_be(:past_grace_period) do
        create(:terraform_state, deleted_at: (described_class::GRACE_PERIOD + 1.minute).ago)
      end

      subject { described_class.ready_for_destruction }

      it { is_expected.not_to include(not_deleted) }
      it { is_expected.not_to include(within_grace_period) }
      it('state deleted exactly at the boundary', :freeze_time) { is_expected.to include(exactly_at_grace_boundary) }
      it { is_expected.to include(past_grace_period) }
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

    context 'when Terraform state file encryption is enabled' do
      let(:terraform_state) { create(:terraform_state) }

      before do
        allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
        stub_application_setting(terraform_state_encryption_enabled: true)
      end

      it 'tracks an encrypted terraform state event' do
        expect(terraform_state).to receive(:track_internal_event).with(
          'terraform_state_stored_with_encryption',
          project: terraform_state.project,
          user: terraform_state.locked_by_user
        )

        subject
      end
    end

    context 'when Terraform state file encryption is disabled' do
      let(:terraform_state) { create(:terraform_state) }

      before do
        allow(ApplicationSetting).to receive(:current).and_return(ApplicationSetting.new)
        stub_application_setting(terraform_state_encryption_enabled: false)
      end

      it 'tracks a unencrypted terraform state event' do
        expect(terraform_state).to receive(:track_internal_event).with(
          'terraform_state_stored_without_encryption',
          project: terraform_state.project,
          user: terraform_state.locked_by_user
        )

        subject
      end
    end
  end

  describe '#permanent_deletion_at' do
    let_it_be(:project) { create(:project) }

    context 'when deleted_at is nil' do
      let_it_be(:state) { create(:terraform_state, project: project, deleted_at: nil) }

      it 'returns nil' do
        expect(state.permanent_deletion_at).to be_nil
      end
    end

    context 'when deleted_at is set' do
      let_it_be(:deleted_at) { 2.days.ago }
      let_it_be(:state) { create(:terraform_state, project: project, deleted_at: deleted_at) }

      it 'returns deleted_at plus GRACE_PERIOD' do
        expect(state.permanent_deletion_at)
          .to be_within(1.second).of(deleted_at + described_class::GRACE_PERIOD)
      end
    end
  end
end
