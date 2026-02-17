# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::FindPipelineInputsService, feature_category: :pipeline_composition do
  include ReactiveCachingHelpers

  let(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:ref) { 'master' }
  let(:pipeline_source) { :web }

  subject(:service) do
    described_class.new(current_user: user, project: project, ref: ref, pipeline_source: pipeline_source)
  end

  before do
    synchronous_reactive_cache(service)
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
        expect(spec_inputs).to be_a(::Ci::Inputs::Builder)
        expect(spec_inputs.errors).to be_empty
        expect(spec_inputs.all_inputs).to be_empty
      end
    end

    shared_examples 'successful response with spec' do
      it 'returns success response with spec' do
        result = service.execute

        expect(result).to be_success

        spec_inputs = result.payload.fetch(:inputs)
        expect(spec_inputs).to be_a(::Ci::Inputs::Builder)
        expect(spec_inputs.errors).to be_empty

        input = spec_inputs.all_inputs.first
        expect(input.name).to eq(:foo)
        expect(input).to be_a(::Ci::Inputs::StringInput)
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
        expect(result.message).to eq(s_('Pipelines|Insufficient permissions to read inputs'))
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
          expect(result.message).to eq(s_('Pipelines|The branch or tag does not exist'))
        end
      end

      context 'when ref is a SHA' do
        let(:ref) { project.commit('master')&.sha }

        it 'returns error response' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(s_('Pipelines|The branch or tag does not exist'))
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
            expect(result.message).to eq(s_('Pipelines|Invalid YAML syntax'))
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
          expect(result.message).to eq(s_('Pipelines|Inputs not supported for this CI config source'))
        end
      end

      context 'when spec contains header includes' do
        let(:config_yaml) do
          <<~YAML
          spec:
            include:
              - local: /inputs.yml
            inputs:
              inline_input:
                default: inline_value
          ---
          job:
            script: echo $[[ inputs.inline_input ]]
          YAML
        end

        let(:external_inputs_yaml) do
          <<~YAML
          inputs:
            external_input:
              default: external_value
          YAML
        end

        before do
          project.repository.create_file(
            project.creator,
            '.gitlab-ci.yml',
            config_yaml,
            message: 'Add CI with header includes',
            branch_name: 'master')

          project.repository.create_file(
            project.creator,
            'inputs.yml',
            external_inputs_yaml,
            message: 'Add external inputs',
            branch_name: 'master')
        end

        it 'processes header includes and merges external inputs' do
          result = service.execute

          expect(result).to be_success

          spec_inputs = result.payload.fetch(:inputs)
          expect(spec_inputs.errors).to be_empty

          input_names = spec_inputs.all_inputs.map(&:name)
          expect(input_names).to include(:external_input, :inline_input)
        end

        it 'gives precedence to inline inputs over external inputs' do
          result = service.execute

          expect(result).to be_success

          spec_inputs = result.payload.fetch(:inputs)
          inline_input = spec_inputs.all_inputs.find { |i| i.name == :inline_input }
          expect(inline_input.default).to eq('inline_value')
        end
      end

      context 'when header include processing fails' do
        let(:config_yaml) do
          <<~YAML
          spec:
            include:
              - local: /non-existent-inputs.yml
          ---
          job:
            script: echo test
          YAML
        end

        before do
          project.repository.create_file(
            project.creator,
            '.gitlab-ci.yml',
            config_yaml,
            message: 'Add CI with invalid header include',
            branch_name: 'master')
        end

        it 'returns error response with include error message' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to match(/Local file .* does not exist/)
        end
      end

      context 'when spec does not contain header includes' do
        let(:config_yaml) do
          <<~YAML
          spec:
            inputs:
              environment:
                default: production
          ---
          job:
            script: echo $[[ inputs.environment ]]
          YAML
        end

        before do
          project.repository.create_file(
            project.creator,
            '.gitlab-ci.yml',
            config_yaml,
            message: 'Add CI without header includes',
            branch_name: 'master')
        end

        it 'processes inputs without header include processing' do
          result = service.execute

          expect(result).to be_success

          spec_inputs = result.payload.fetch(:inputs)
          expect(spec_inputs.errors).to be_empty
          expect(spec_inputs.all_inputs.first.name).to eq(:environment)
          expect(spec_inputs.all_inputs.first.default).to eq('production')
        end
      end

      context 'with reactive caching' do
        it 'sets reactive_cache_work_type to external_dependency' do
          expect(described_class.reactive_cache_work_type).to eq(:external_dependency)
        end

        it 'uses custom reactive_cache_key' do
          expect(described_class.reactive_cache_key.call(service)).to eq(
            [described_class.name, service.id]
          )
        end

        context 'when ci_pipeline_inputs_reactive_cache feature flag is disabled' do
          before do
            stub_feature_flags(ci_pipeline_inputs_reactive_cache: false)
            project.repository.create_file(
              project.creator, '.gitlab-ci.yml', config_yaml,
              message: 'Add CI', branch_name: 'master')
          end

          it 'returns inputs directly without caching' do
            expect(service).not_to receive(:with_reactive_cache)
            result = service.execute
            expect(result).to be_success
          end
        end

        context 'when ci_pipeline_inputs_reactive_cache feature flag is enabled' do
          before do
            stub_feature_flags(ci_pipeline_inputs_reactive_cache: true)
          end

          context 'when cache is not populated' do
            before do
              allow(service).to receive(:with_reactive_cache).and_return(nil)
            end

            it 'returns nil' do
              expect(service.execute).to be_nil
            end
          end
        end
      end
    end
  end

  describe '#id' do
    it 'returns a composite id with project, user, pipeline_source, and ref' do
      expect(service.id).to eq("#{project.id}|#{user.id}|web|master")
    end
  end

  describe '.from_cache' do
    let(:cache_id) { "#{project.id}|#{user.id}|web|master" }

    it 'reconstructs the service from the cache id' do
      reconstructed = described_class.from_cache(cache_id)

      expect(reconstructed.send(:project)).to eq(project)
      expect(reconstructed.send(:current_user)).to eq(user)
      expect(reconstructed.send(:ref)).to eq('master')
      expect(reconstructed.send(:pipeline_source)).to eq(:web)
    end
  end
end
