# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Workloads::RunWorkloadService, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:image) { 'test_docker_image' }
  let_it_be(:source) { :duo_workflow }
  let_it_be(:commands) { ['echo hello world'] }
  let_it_be(:variables) { { 'MY_ENV_VAR' => 'my env var value' } }

  let_it_be(:workload_definition) do
    definition = ::Ci::Workloads::WorkloadDefinition.new
    definition.image = image
    definition.commands = commands
    definition.variables = variables
    definition
  end

  let(:create_branch) { false }

  describe '#execute' do
    subject(:execute) do
      described_class
        .new(
          project: project,
          current_user: user,
          source: source,
          workload_definition: workload_definition,
          create_branch: create_branch
        ).execute
    end

    context 'when pipeline creation is success' do
      before do
        create(:ci_variable, key: 'A_PROJECT_VARIABLE', project: project)
        create(:ci_group_variable, key: 'A_GROUP_VARIABLE', group: group)
        create(:ci_instance_variable, key: 'A_INSTANCE_VARIABLE')
      end

      it 'starts a pipeline to execute workload' do
        expect_next_instance_of(Ci::CreatePipelineService, project, user,
          hash_including(ref: project.default_branch_or_main)) do |pipeline_service|
          expect(pipeline_service).to receive(:execute)
                                        .and_call_original
        end
        result = execute
        expect(result).to be_success

        workload = result.payload
        expect(workload).to be_a(Ci::Workloads::Workload)
        expect(workload.pipeline).to be_present
      end

      it 'does not include project/group/instance variables' do
        result = execute
        expect(result).to be_success

        pipeline = result.payload.pipeline
        build = pipeline.builds.first
        expect(build.variables.map(&:key)).not_to include('A_PROJECT_VARIABLE')
        expect(build.variables.map(&:key)).not_to include('A_GROUP_VARIABLE')
        expect(build.variables.map(&:key)).not_to include('A_INSTANCE_VARIABLE')
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

      context 'when create_branch: true' do
        let(:create_branch) { true }

        it 'creates a new branch with skip_ci and manually runs the pipeline for that branch' do
          expect(project.repository).to receive(:add_branch)
            .with(user, match(%r{^workloads/\w+}), project.default_branch_or_main, skip_ci: true)
            .and_call_original

          result = execute
          expect(result).to be_success

          workload = result.payload
          expect(workload.branch_name).to match(%r{workloads/\w+})
        end
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
  end
end
