# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Workloads::RunWorkloadService, feature_category: :continuous_integration do
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :small_repo, group: group) }
  let_it_be_with_reload(:user) { create(:user, maintainer_of: project) }
  let_it_be(:image, freeze: false) { 'test_docker_image' }
  let_it_be(:source, freeze: false) { :duo_workflow }
  let_it_be(:commands, freeze: false) { ['echo hello world'] }
  let_it_be(:variables, freeze: false) { { 'MY_ENV_VAR' => 'my env var value' } }

  let_it_be(:workload_definition, freeze: false) do
    definition = ::Ci::Workloads::WorkloadDefinition.new
    definition.image = image
    definition.commands = commands
    definition.variables = variables
    definition
  end

  let(:ref) { 'workloads/123' }

  describe '#execute' do
    subject(:execute) do
      described_class
        .new(
          project: project,
          current_user: user,
          source: source,
          workload_definition: workload_definition,
          ref: ref,
          ci_variables_included: %w[A_PROJECT_VARIABLE A_GROUP_VARIABLE A_INSTANCE_VARIABLE]
        ).execute
    end

    before do
      project.repository.create_branch('workloads/123', project.default_branch)
    end

    context 'when pipeline creation is success' do
      before do
        create(:ci_variable, key: 'A_PROJECT_VARIABLE', project: project)
        create(:ci_group_variable, key: 'A_GROUP_VARIABLE', group: group)
        create(:ci_variable, key: 'A_PROJECT_VARIABLE_NOT_INCLUDED', project: project)
        create(:ci_group_variable, key: 'A_GROUP_VARIABLE_NOT_INCLUDED', group: group)
        create(:ci_instance_variable, key: 'A_INSTANCE_VARIABLE')
        create(:ci_instance_variable, key: 'A_INSTANCE_VARIABLE_NOT_INCLUDED')
      end

      it 'starts a pipeline to execute workload' do
        expect_next_instance_of(Ci::CreatePipelineService, project, user,
          hash_including(ref: ref)) do |pipeline_service|
          expect(pipeline_service).to receive(:execute)
                                        .and_call_original
        end
        result = execute
        expect(result).to be_success

        workload = result.payload
        expect(workload).to be_a(Ci::Workloads::Workload)
        expect(workload.pipeline).to be_present
      end

      it 'only includes explicitly included project/group/instance variables' do
        result = execute
        expect(result).to be_success

        pipeline = result.payload.pipeline
        build = pipeline.builds.first

        # Refind it because it remembers CI variables initialized when it was created.
        # Workload variables are only added when we recalculate the variables
        build = Ci::Build.find(build.id)

        expect(build.variables.map(&:key)).to include('A_PROJECT_VARIABLE')
        expect(build.variables.map(&:key)).to include('A_GROUP_VARIABLE')
        expect(build.variables.map(&:key)).to include('A_INSTANCE_VARIABLE')
        expect(build.variables.map(&:key)).not_to include('A_PROJECT_VARIABLE_NOT_INCLUDED')
        expect(build.variables.map(&:key)).not_to include('A_GROUP_VARIABLE_NOT_INCLUDED')
        expect(build.variables.map(&:key)).not_to include('A_INSTANCE_VARIABLE_NOT_INCLUDED')
      end

      it 'adds the CI_WORKLOAD_REF variable' do
        result = execute

        expect(result).to be_success

        pipeline = result.payload.pipeline
        build = pipeline.builds.first
        variable = build.variables.find { |v| v.key == 'CI_WORKLOAD_REF' }
        expect(variable).to be_present
        expect(variable.value).to match(pipeline.ref)
      end

      context 'when ref is nil' do
        let(:ref) { nil }

        it 'uses project default branch' do
          result = execute
          expect(result).to be_success
        end
      end
    end

    context 'with internal refs for workloads' do
      let(:ref) { 'refs/workloads/123' }

      before do
        source_ref = project.default_branch_or_main
        source_sha = project.repository.commit(source_ref)&.sha
        project.repository.create_ref(source_sha, ref)
      end

      it 'starts a pipeline to execute workload' do
        expect_next_instance_of(Ci::CreatePipelineService, project, user,
          hash_including(ref: ref)) do |pipeline_service|
          expect(pipeline_service).to receive(:execute)
                                        .and_call_original
        end
        result = execute
        expect(result).to be_success

        workload = result.payload
        expect(workload).to be_a(Ci::Workloads::Workload)
        expect(workload.pipeline).to be_present
      end
    end

    context 'with unsupported source' do
      let(:source) { :foo }

      it 'raises an error' do
        expect { execute }.to raise_error(ArgumentError, "unsupported source `foo` for workloads")
      end
    end

    context 'when ci pipeline could not be created' do
      let(:pipeline) do
        instance_double(Ci::Pipeline, created_successfully?: false, full_error_messages: 'I am an error')
      end

      let(:service_response) { ServiceResponse.error(message: 'Error in creating pipeline', payload: pipeline) }

      before do
        allow_next_instance_of(::Ci::CreatePipelineService) do |instance|
          allow(instance).to receive(:execute).and_return(service_response)
        end
      end

      it 'does not start a pipeline to execute workflow' do
        expect(execute).to be_error
        expect(execute.message).to eq('Error in creating workload: I am an error')
      end
    end

    context 'with suspend_on_success' do
      let(:workload_definition) do
        ::Ci::Workloads::WorkloadDefinition.new.tap do |definition|
          definition.image = image
          definition.commands = commands
          definition.suspend_on_success = true
        end
      end

      it 'sets suspend_on_success in build options under suspend_options' do
        result = execute
        expect(result).to be_success

        build = result.payload.pipeline.builds.first
        expect(build.options.dig(:suspend_options, :suspend_on_success)).to be(true)
      end

      it 'creates a Ci::JobRuntimeEnvironment row with suspend_on_success set', :aggregate_failures do
        result = execute
        expect(result).to be_success

        build = result.payload.pipeline.builds.first
        job_runtime_environment = build.job_runtime_environment
        expect(job_runtime_environment).to be_present
        expect(job_runtime_environment.suspend_on_success).to be(true)
        expect(job_runtime_environment.suspend_on_failure).to be(false)
      end

      context 'when the feature flag is disabled for the project' do
        before do
          stub_feature_flags(ci_suspendable_environment_runner_routing: false)
        end

        it 'does not create a Ci::JobRuntimeEnvironment row' do
          result = execute
          expect(result).to be_success

          build = result.payload.pipeline.builds.first
          expect(build.job_runtime_environment).to be_nil
        end
      end
    end

    context 'with environment_key for resume' do
      let(:environment_key) { '42/machine-id/executor-specific-data' }

      let(:workload_definition) do
        ::Ci::Workloads::WorkloadDefinition.new.tap do |definition|
          definition.image = image
          definition.commands = commands
          definition.environment_key = environment_key
        end
      end

      it 'sets environment_key in build options under suspend_options' do
        result = execute
        expect(result).to be_success

        build = result.payload.pipeline.builds.first
        expect(build.options.dig(:suspend_options, :environment_key)).to eq('42/machine-id/executor-specific-data')
      end

      context 'when a matching Ci::RuntimeEnvironment already exists' do
        let!(:runtime_environment) do
          create(:ci_runtime_environment, project: project, environment_key: environment_key)
        end

        it 'links the build runtime environment to it' do
          result = execute
          expect(result).to be_success

          build = result.payload.pipeline.builds.first
          expect(build.job_runtime_environment.runtime_environment_id).to eq(runtime_environment.id)
        end
      end

      context 'when no matching Ci::RuntimeEnvironment exists yet' do
        it 'still creates a row, with runtime_environment_id nil' do
          result = execute
          expect(result).to be_success

          build = result.payload.pipeline.builds.first
          job_runtime_environment = build.job_runtime_environment
          expect(job_runtime_environment).to be_present
          expect(job_runtime_environment.runtime_environment_id).to be_nil
        end
      end
    end

    context 'without suspend options' do
      it 'does not include suspend_options in build options' do
        result = execute
        expect(result).to be_success

        build = result.payload.pipeline.builds.first
        expect(build.options).not_to have_key(:suspend_options)
      end

      it 'does not create a Ci::JobRuntimeEnvironment row' do
        result = execute
        expect(result).to be_success

        build = result.payload.pipeline.builds.first
        expect(build.job_runtime_environment).to be_nil
      end
    end

    context 'when duo_workflow_definition is provided' do
      subject(:execute) do
        described_class
          .new(
            project: project,
            current_user: user,
            source: source,
            workload_definition: workload_definition,
            ref: ref,
            duo_workflow_definition: 'sast_fp_detection/v1'
          ).execute
      end

      it 'forwards duo_workflow_definition to CreatePipelineService' do
        expect_next_instance_of(Ci::CreatePipelineService, project, user,
          hash_including(ref: ref)) do |pipeline_service|
          expect(pipeline_service).to receive(:execute)
            .with(:duo_workflow,
              ignore_skip_ci: true,
              save_on_errors: false,
              content: anything,
              duo_workflow_definition: 'sast_fp_detection/v1',
              suspend_options: nil)
            .and_call_original
        end

        execute
      end
    end
  end
end
