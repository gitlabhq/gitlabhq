# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildRuntimeEnvironment, feature_category: :runner_core do
  describe 'associations' do
    it { is_expected.to belong_to(:build).class_name('Ci::Build') }
    it { is_expected.to belong_to(:runtime_environment).class_name('Ci::RuntimeEnvironment').optional }
    it { is_expected.to belong_to(:runner_manager).class_name('Ci::RunnerManager').optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:build) }
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe 'suspension triggers' do
    it 'default to false' do
      expect(build(:ci_build_runtime_environment))
        .to have_attributes(suspend_on_success: false, suspend_on_failure: false)
    end
  end

  describe 'composite foreign key on :build' do
    let_it_be(:record) { create(:ci_build_runtime_environment) }

    it 'joins the build on both build_id and partition_id' do
      expect(described_class.reflect_on_association(:build).foreign_key)
        .to contain_exactly('build_id', 'partition_id')
    end

    it 'loads the associated build within the record partition' do
      reloaded = described_class.find_by(build_id: record.build_id, partition_id: record.partition_id)

      expect(reloaded.build).to eq(record.build)
      expect(reloaded.build.partition_id).to eq(record.partition_id)
    end

    it 'is reachable from the build via the has_one inverse' do
      expect(record.build.build_runtime_environment).to eq(record)
    end
  end

  describe '#ensure_project_id' do
    it 'derives project_id from the build when not set' do
      record = build(:ci_build_runtime_environment, project_id: nil)

      record.valid?

      expect(record.project_id).to eq(record.build.project_id)
    end

    it 'does not override an explicitly set project_id' do
      other_project_id = non_existing_record_id
      record = build(:ci_build_runtime_environment, project_id: other_project_id)

      record.valid?

      expect(record.project_id).to eq(other_project_id)
    end
  end

  describe 'when the runtime_environment is removed' do
    let_it_be(:record) { create(:ci_build_runtime_environment) }

    it 'keeps the mapping row and leaves runtime_environment_id dangling' do
      runtime_environment = record.runtime_environment

      expect { runtime_environment.destroy! }
        .not_to change { described_class.exists?(build_id: record.build_id, partition_id: record.partition_id) }
        .from(true)

      expect(record.reload.runtime_environment_id).to eq(runtime_environment.id)
    end
  end
end
