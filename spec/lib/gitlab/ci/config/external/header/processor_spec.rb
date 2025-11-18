# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Header::Processor, feature_category: :pipeline_composition do
  include StubRequests
  include RepoHelpers

  let_it_be(:user) { create(:user) }

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be_with_reload(:another_project) { create(:project, :repository) }

  let(:project_files) { {} }
  let(:other_project_files) { {} }

  let(:sha) { project.commit.sha }
  let(:context_params) { { project: project, sha: sha, user: user } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }

  subject(:processor) { described_class.new(values, context) }

  around do |example|
    create_and_delete_files(project, project_files) do
      create_and_delete_files(another_project, other_project_files) do
        example.run
      end
    end
  end

  before_all do
    project.add_developer(user)
  end

  before do
    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  describe '#perform' do
    # Shared examples setup
    let(:base_values) do
      {
        inputs: {
          inline_input: { default: 'inline_value' }
        }
      }
    end

    let(:invalid_local_file_include) { '/non-existent-inputs.yml' }
    let(:invalid_remote_file) { 'http://doesntexist.com/inputs.yml' }

    let(:valid_local_file_include) { '/inputs.yml' }
    let(:valid_remote_file) { 'https://example.com/inputs.yml' }

    let(:valid_remote_file_content) do
      <<~YAML
        inputs:
          remote_input:
            default: 'remote_value'
      YAML
    end

    let(:project_files) do
      {
        '/inputs.yml' => <<~YAML
          inputs:
            local_input:
              default: 'local_value'
        YAML
      }
    end

    let(:multiple_includes) do
      [
        { local: '/inputs.yml' },
        { remote: valid_remote_file }
      ]
    end

    # Use shared examples
    it_behaves_like 'returns values when no includes defined'
    it_behaves_like 'handles invalid local files'
    it_behaves_like 'handles invalid remote files'
    it_behaves_like 'processes valid external files'
    it_behaves_like 'processes multiple external files'

    # Header-specific tests
    context 'with valid local file containing inputs' do
      let(:values) do
        {
          include: [{ local: '/shared-inputs.yml' }],
          inputs: {
            region: { default: 'us-west-2' }
          }
        }
      end

      let(:project_files) do
        {
          '/shared-inputs.yml' => <<~YAML
            inputs:
              database:
                default: 'postgres'
              region:
                default: 'us-east-1'
              cache_enabled:
                default: true
          YAML
        }
      end

      it 'merges inputs with inline inputs taking precedence' do
        result = processor.perform
        expect(result[:inputs]).to eq({
          database: { default: 'postgres' },
          region: { default: 'us-west-2' },
          cache_enabled: { default: true }
        })
      end

      it 'removes the include key' do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'with multiple local files' do
      let(:values) do
        {
          include: [
            { local: '/base-inputs.yml' },
            { local: '/override-inputs.yml' }
          ],
          inputs: {
            timeout: { default: 3600 }
          }
        }
      end

      let(:project_files) do
        {
          '/base-inputs.yml' => <<~YAML,
            inputs:
              database:
                default: 'postgres'
              cache_enabled:
                default: true
          YAML
          '/override-inputs.yml' => <<~YAML
            inputs:
              database:
                default: 'mysql'
              region:
                default: 'eu-west-1'
          YAML
        }
      end

      it 'merges all inputs in order with later files taking precedence' do
        result = processor.perform
        expect(result[:inputs]).to eq({
          database: { default: 'mysql' },
          cache_enabled: { default: true },
          region: { default: 'eu-west-1' },
          timeout: { default: 3600 }
        })
      end
    end

    context 'with a valid project file' do
      let(:values) do
        {
          include: [
            {
              project: another_project.full_path,
              file: '/shared-inputs.yml',
              ref: 'master'
            }
          ],
          inputs: {
            local_input: { default: 'value' }
          }
        }
      end

      let(:other_project_files) do
        {
          '/shared-inputs.yml' => <<~YAML
            inputs:
              shared_database:
                default: 'postgres'
              shared_cache:
                default: true
          YAML
        }
      end

      before_all do
        another_project.add_developer(user)
      end

      it 'merges project inputs with inline inputs' do
        result = processor.perform
        expect(result[:inputs]).to eq({
          shared_database: { default: 'postgres' },
          shared_cache: { default: true },
          local_input: { default: 'value' }
        })
      end
    end

    context 'when included file contains non-input keys' do
      let(:values) do
        {
          include: [{ local: '/invalid-inputs.yml' }],
          inputs: {
            foo: { default: 'bar' }
          }
        }
      end

      let(:project_files) do
        {
          '/invalid-inputs.yml' => <<~YAML
            inputs:
              database:
                default: 'postgres'
            test:
              script: echo "test"
          YAML
        }
      end

      it 'raises an error about unknown keys' do
        expect { processor.perform }.to raise_error(
          described_class::IncludeError,
          /Header include file .* contains unknown keys: \[:test\]/
        )
      end
    end

    context 'when included file is empty' do
      let(:values) do
        {
          include: [{ local: '/empty-inputs.yml' }],
          inputs: {
            foo: { default: 'bar' }
          }
        }
      end

      let(:project_files) do
        {
          '/empty-inputs.yml' => ''
        }
      end

      it 'raises an error' do
        expect { processor.perform }.to raise_error(
          described_class::IncludeError,
          /Local file .* is empty/
        )
      end
    end

    context 'when included file has only inputs key with no content' do
      let(:values) do
        {
          include: [{ local: '/empty-content-inputs.yml' }],
          inputs: {
            foo: { default: 'bar' }
          }
        }
      end

      let(:project_files) do
        {
          '/empty-content-inputs.yml' => <<~YAML
            inputs:
          YAML
        }
      end

      it 'merges with inline inputs only' do
        result = processor.perform
        expect(result[:inputs]).to eq({
          foo: { default: 'bar' }
        })
      end
    end

    context 'with nested input structures' do
      let(:values) do
        {
          include: [{ local: '/nested-inputs.yml' }],
          inputs: {
            config: {
              options: ['opt3']
            }
          }
        }
      end

      let(:project_files) do
        {
          '/nested-inputs.yml' => <<~YAML
            inputs:
              config:
                default: 'value'
                options: ['opt1', 'opt2']
          YAML
        }
      end

      it 'performs deep merge of input structures' do
        result = processor.perform
        expect(result[:inputs][:config][:options]).to eq(['opt3'])
        expect(result[:inputs][:config][:default]).to eq('value')
      end
    end
  end
end
