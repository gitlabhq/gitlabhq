# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RuntimeEnvironments::RecordSuccessfulSuspensionService,
  feature_category: :runner_core do
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :running, pipeline: pipeline) }
  let(:environment_key) { '22/s_system-xid-abc/acquisition-key="test-key"' }

  # runtime_environment: nil is required - the factory default sets runtime_environment_id,
  # which would trip the idempotency guard and silently prevent RuntimeEnvironment creation.
  let(:job_runtime_environment) do
    create(:ci_job_runtime_environment,
      build: build,
      runtime_environment: nil,
      suspend_on_success: true)
  end

  subject(:execute) { described_class.new(build, environment_key: environment_key).execute }

  before do
    job_runtime_environment
    stub_feature_flags(ci_suspendable_environment_runner_routing: project)
  end

  context 'when environment_key is blank' do
    let(:environment_key) { '' }

    it 'does not create a Ci::RuntimeEnvironment' do
      expect { execute }.not_to change { Ci::RuntimeEnvironment.count }
    end
  end

  context 'when environment_key is nil' do
    let(:environment_key) { nil }

    it 'does not create a Ci::RuntimeEnvironment' do
      expect { execute }.not_to change { Ci::RuntimeEnvironment.count }
    end
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(ci_suspendable_environment_runner_routing: false)
    end

    it 'does not create a Ci::RuntimeEnvironment' do
      expect { execute }.not_to change { Ci::RuntimeEnvironment.count }
    end
  end

  context 'when suspend_on_success is false' do
    let(:job_runtime_environment) do
      create(:ci_job_runtime_environment,
        build: build,
        runtime_environment: nil,
        suspend_on_success: false,
        suspend_on_failure: true)
    end

    it 'does not create a Ci::RuntimeEnvironment' do
      expect { execute }.not_to change { Ci::RuntimeEnvironment.count }
    end
  end

  context 'when build has no job_runtime_environment' do
    let(:build_without_jre) { create(:ci_build, :running, pipeline: pipeline) }

    it 'does not raise an error' do
      expect(build_without_jre.job_runtime_environment).to be_nil

      expect { described_class.new(build_without_jre, environment_key: environment_key).execute }
        .not_to raise_error
    end

    it 'does not create a Ci::RuntimeEnvironment' do
      expect { described_class.new(build_without_jre, environment_key: environment_key).execute }
        .not_to change { Ci::RuntimeEnvironment.count }
    end
  end

  context 'when environment_key is valid and suspend_on_success is true' do
    it 'creates a Ci::RuntimeEnvironment with the right key and project', :aggregate_failures do
      expect { execute }.to change { Ci::RuntimeEnvironment.count }.by(1)

      runtime_env = job_runtime_environment.reload.runtime_environment
      expect(runtime_env.environment_key).to eq(environment_key)
      expect(runtime_env.project_id).to eq(build.project_id)
    end

    it 'links the runtime_environment onto job_runtime_environment' do
      execute

      expect(job_runtime_environment.reload.runtime_environment_id).not_to be_nil
    end

    context 'when called twice' do
      it 'creates exactly one Ci::RuntimeEnvironment' do
        expect do
          described_class.new(build, environment_key: environment_key).execute
          described_class.new(build, environment_key: environment_key).execute
        end.to change { Ci::RuntimeEnvironment.count }.by(1)
      end

      it 'leaves the association stable' do
        described_class.new(build, environment_key: environment_key).execute
        first_id = job_runtime_environment.reload.runtime_environment_id

        described_class.new(build, environment_key: environment_key).execute
        expect(job_runtime_environment.reload.runtime_environment_id).to eq(first_id)
      end
    end
  end

  context 'when runtime_environment_id is already set with the same key (retry scenario)' do
    let!(:existing_runtime_env) do
      create(:ci_runtime_environment, project: project, environment_key: environment_key)
    end

    let(:job_runtime_environment) do
      create(:ci_job_runtime_environment,
        build: build,
        runtime_environment: existing_runtime_env,
        suspend_on_success: true)
    end

    it 'does not create a second Ci::RuntimeEnvironment' do
      expect { execute }.not_to change { Ci::RuntimeEnvironment.count }
    end

    it 'does not change the existing link' do
      execute

      expect(job_runtime_environment.reload.runtime_environment_id).to eq(existing_runtime_env.id)
    end
  end

  context 'when the build resumed from one environment and suspends into a new one' do
    let(:resumed_from_env) { create(:ci_runtime_environment, project: project) }
    let(:job_runtime_environment) do
      create(:ci_job_runtime_environment,
        build: build,
        runtime_environment: resumed_from_env,
        suspend_on_success: true)
    end

    it 'creates a new Ci::RuntimeEnvironment for the new key' do
      expect { execute }.to change { Ci::RuntimeEnvironment.count }.by(1)
    end

    it 'updates the link to point at the new environment' do
      execute

      new_env = Ci::RuntimeEnvironment.find_by(environment_key: environment_key)
      expect(job_runtime_environment.reload.runtime_environment_id).to eq(new_env.id)
    end
  end
end
