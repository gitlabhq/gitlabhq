# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobRuntimeEnvironment, feature_category: :runner_core do
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
      expect(build(:ci_job_runtime_environment))
        .to have_attributes(suspend_on_success: false, suspend_on_failure: false)
    end
  end

  describe 'composite foreign key on :build' do
    let_it_be(:record) { create(:ci_job_runtime_environment) }

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
      expect(record.build.job_runtime_environment).to eq(record)
    end
  end

  describe '#ensure_project_id' do
    it 'derives project_id from the build when not set' do
      record = build(:ci_job_runtime_environment, project_id: nil)

      record.valid?

      expect(record.project_id).to eq(record.build.project_id)
    end

    it 'does not override an explicitly set project_id' do
      other_project_id = non_existing_record_id
      record = build(:ci_job_runtime_environment, project_id: other_project_id)

      record.valid?

      expect(record.project_id).to eq(other_project_id)
    end
  end

  describe 'when the runtime_environment is removed' do
    let_it_be(:record) { create(:ci_job_runtime_environment) }

    it 'keeps the mapping row and leaves runtime_environment_id dangling' do
      runtime_environment = record.runtime_environment

      expect { runtime_environment.destroy! }
        .not_to change { described_class.exists?(build_id: record.build_id, partition_id: record.partition_id) }
        .from(true)

      expect(record.reload.runtime_environment_id).to eq(runtime_environment.id)
    end
  end

  describe '.runner_machine_id_for' do
    let_it_be(:runtime_environment) { create(:ci_runtime_environment) }
    let_it_be(:runner_manager) { create(:ci_runner_machine) }

    context 'when the feature flag is disabled for the project' do
      let_it_be(:record) do
        create(:ci_job_runtime_environment, runtime_environment: runtime_environment,
          runner_machine_id: runner_manager.id)
      end

      before do
        stub_feature_flags(ci_suspendable_environment_runner_routing: false)
      end

      it 'returns nil' do
        expect(described_class.runner_machine_id_for(record.build)).to be_nil
      end
    end

    context 'when the build has no job_runtime_environment' do
      let_it_be(:build_without_environment) { create(:ci_build) }

      it 'returns nil' do
        expect(described_class.runner_machine_id_for(build_without_environment)).to be_nil
      end
    end

    context 'when the build has a job_runtime_environment but no linked runtime_environment yet' do
      let_it_be(:record) { create(:ci_job_runtime_environment, runtime_environment: nil, suspend_on_success: true) }

      it 'returns nil' do
        expect(described_class.runner_machine_id_for(record.build)).to be_nil
      end
    end

    context "when the build's own job_runtime_environment has a runner machine recorded" do
      let_it_be(:record) do
        create(:ci_job_runtime_environment, runtime_environment: runtime_environment,
          runner_machine_id: runner_manager.id)
      end

      it 'returns that runner machine id' do
        expect(described_class.runner_machine_id_for(record.build)).to eq(runner_manager.id)
      end
    end

    context 'when a sibling job_runtime_environment on the same runtime environment has a runner machine recorded' do
      let_it_be(:record) { create(:ci_job_runtime_environment, runtime_environment: runtime_environment) }
      let_it_be(:sibling_record) do
        create(:ci_job_runtime_environment, runtime_environment: runtime_environment,
          runner_machine_id: runner_manager.id)
      end

      it 'returns the sibling runner machine id' do
        expect(described_class.runner_machine_id_for(record.build)).to eq(runner_manager.id)
      end
    end

    context 'when no row for the runtime environment has a runner machine recorded yet' do
      let_it_be(:record) { create(:ci_job_runtime_environment, runtime_environment: runtime_environment) }

      it 'returns nil' do
        expect(described_class.runner_machine_id_for(record.build)).to be_nil
      end
    end
  end
end
