# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::FindPipelineInputsService, feature_category: :pipeline_composition do
  let(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:ref) { 'master' }
  let(:pipeline_source) { :web }

  subject(:service) do
    described_class.new(current_user: user, project: project, ref: ref, pipeline_source: pipeline_source)
  end

  describe '#execute' do
    let(:config_yaml_without_inputs) do
      <<~YAML
      job:
        script: echo hello world
      YAML
    end

    let(:config_yaml) do
      <<~YAML
      spec:
        inputs:
          foo:
            default: bar
      ---
      job:
        script: echo hello world
      YAML
    end

    shared_examples 'successful response without spec' do
      let(:config_yaml) { config_yaml_without_inputs }

      it 'returns success response without spec' do
        result = service.execute

        expect(result).to be_success

        spec_inputs = result.payload.fetch(:inputs)
        expect(spec_inputs).to be_a(::Ci::PipelineCreation::Inputs::SpecInputs)
        expect(spec_inputs.errors).to be_empty
        expect(spec_inputs.all_inputs).to be_empty
      end
    end

    shared_examples 'successful response with spec' do
      it 'returns success response with spec' do
        result = service.execute

        expect(result).to be_success

        spec_inputs = result.payload.fetch(:inputs)
        expect(spec_inputs).to be_a(::Ci::PipelineCreation::Inputs::SpecInputs)
        expect(spec_inputs.errors).to be_empty

        input = spec_inputs.all_inputs.first
        expect(input.name).to eq(:foo)
        expect(input).to be_a(::Ci::PipelineCreation::Inputs::StringInput)
        expect(input.default).to eq('bar')
      end
    end

    context 'when user does not have permission to read code' do
      before do
        project.add_guest(user)
      end

      it 'returns error response' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('insufficient permissions to read inputs')
      end
    end

    context 'when user has permissions to read code' do
      before do
        project.add_developer(user)
      end

      context 'when ref does not exist' do
        let(:ref) { 'non-existent-branch' }

        it 'returns error response' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('ref can only be an existing branch or tag')
        end
      end

      context 'when ref is a SHA' do
        let(:ref) { project.commit('master')&.sha }

        it 'returns error response' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('ref can only be an existing branch or tag')
        end
      end

      context 'when config does not exist and AutoDevOps is disabled' do
        before do
          allow(project).to receive(:auto_devops_enabled?).and_return(false)
        end

        it 'returns success response with empty inputs' do
          result = service.execute

          expect(result).to be_success
          expect(result.payload[:inputs].all_inputs).to be_empty
        end
      end

      context 'when config is expected in the project' do
        before do
          project.repository.create_file(
            project.creator,
            '.gitlab-ci.yml',
            config_yaml,
            message: 'Add CI',
            branch_name: 'master')
        end

        it_behaves_like 'successful response with spec'
        it_behaves_like 'successful response without spec'

        context 'when an error occurs during yaml processing' do
          let(:config_yaml) do
            <<~YAML
            a*
            test: <<a
            YAML
          end

          it 'returns error response' do
            result = service.execute

            expect(result).to be_error
            expect(result.message).to eq('invalid YAML config')
          end
        end
      end

      context 'when an error occurs during yaml loading' do
        it 'returns error response' do
          allow(::Gitlab::Ci::Config::Yaml)
            .to receive(:load!)
            .and_raise(::Gitlab::Ci::Config::Yaml::LoadError)

          result = service.execute

          expect(result).to be_error
          expect(result.message).to match(/YAML load error/)
        end
      end

      context 'when config is expected on another project' do
        let!(:another_project) { create(:project, :repository) }

        before do
          another_project.add_developer(user)
          another_project.repository.create_file(
            another_project.creator,
            'config.yml',
            config_yaml,
            message: 'Add CI',
            branch_name: 'master')

          project.update!(ci_config_path: "config.yml@#{another_project.full_path}")
        end

        it_behaves_like 'successful response with spec'
        it_behaves_like 'successful response without spec'
      end

      context 'when config exists without internal include' do
        before do
          allow_next_instance_of(Gitlab::Ci::ProjectConfig) do |config|
            allow(config).to receive_messages(exists?: true, internal_include_prepended?: false)
          end
        end

        it 'returns error response' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('inputs not supported for this CI config source')
        end
      end
    end
  end
end
