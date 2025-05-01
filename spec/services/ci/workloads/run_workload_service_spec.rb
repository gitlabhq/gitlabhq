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
  let_it_be(:workload) { ::Ci::Workloads::Workload.new }
  let_it_be(:ci_job) do
    {
      image: image,
      script: commands,
      variables: variables
    }
  end

  let(:create_branch) { false }

  describe '#execute' do
    subject(:execute) do
      described_class
        .new(project: project, current_user: user, source: source, workload: workload, create_branch: create_branch)
        .execute
    end

    context 'when pipeline creation is success' do
      before do
        allow(workload).to receive(:job).and_return(ci_job)
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
        expect(execute).to be_success
        expect(execute.payload).to be_a(Ci::Pipeline)

        pipeline = execute.payload
        expect(pipeline.full_error_messages).to eq('')
      end

      it 'does not include project/group/instance variables' do
        expect(execute).to be_success

        pipeline = execute.payload
        build = pipeline.builds.first
        expect(build.variables.map(&:key)).not_to include('A_PROJECT_VARIABLE')
        expect(build.variables.map(&:key)).not_to include('A_GROUP_VARIABLE')
        expect(build.variables.map(&:key)).not_to include('A_INSTANCE_VARIABLE')
      end

      it 'sets the branch on the workload to the project default_branch' do
        pipeline = execute.payload

        expect(pipeline.ref).to eq("master")
        expect(pipeline.ref).to eq(workload.instance_variable_get(:@branch))
      end

      context 'when create_branch: true' do
        let(:create_branch) { true }

        it 'creates a new branch with skip_ci and manually runs the pipeline for that branch' do
          expect(project.repository).to receive(:add_branch)
            .with(user, match(%r{^workloads/\w+}), project.default_branch_or_main, skip_ci: true)
            .and_call_original

          expect(execute).to be_success

          pipeline = execute.payload
          expect(pipeline.ref).to match(%r{workloads/\w+})
        end

        it 'sets the branch on the workload to the created branch' do
          pipeline = execute.payload
          expect(pipeline.ref).to eq(workload.instance_variable_get(:@branch))
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
        allow(workload).to receive(:job).and_return(ci_job)
        allow_next_instance_of(::Ci::CreatePipelineService) do |instance|
          allow(instance).to receive(:execute).and_return(service_response)
        end
      end

      it 'does not start a pipeline to execute workflow' do
        expect(execute).to be_error
        expect(execute.message).to eq('Error in creating pipeline')

        pipeline = execute.payload
        expect(pipeline.full_error_messages).to eq('I am an error')
      end
    end
  end
end
