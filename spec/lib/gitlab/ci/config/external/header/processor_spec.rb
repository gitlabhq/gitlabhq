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
    context 'with valid local file containing inputs and no duplicates' do
      let(:values) do
        {
          include: [{ local: '/shared-inputs.yml' }],
          inputs: {
            timeout: { default: 3600 }
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

      it 'merges inputs from external file and inline spec' do
        result = processor.perform
        expect(result[:inputs]).to eq({
          database: { default: 'postgres' },
          region: { default: 'us-east-1' },
          cache_enabled: { default: true },
          timeout: { default: 3600 }
        })
      end

      it 'removes the include key' do
        expect(processor.perform[:include]).to be_nil
      end
    end

    context 'with valid local file containing duplicate input with inline spec' do
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

      it 'raises DuplicateInputError for inline input duplicating external file' do
        expect { processor.perform }.to raise_error(
          described_class::DuplicateInputError,
          "Duplicate input keys found: region. " \
            "Input keys must be unique across all included files and inline specifications."
        )
      end
    end

    context 'with multiple local files without duplicates' do
      let(:values) do
        {
          include: [
            { local: '/base-inputs.yml' },
            { local: '/additional-inputs.yml' }
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
          '/additional-inputs.yml' => <<~YAML
            inputs:
              region:
                default: 'eu-west-1'
              max_retries:
                default: 3
          YAML
        }
      end

      it 'merges all inputs from multiple files' do
        result = processor.perform
        expect(result[:inputs]).to eq({
          database: { default: 'postgres' },
          cache_enabled: { default: true },
          region: { default: 'eu-west-1' },
          max_retries: { default: 3 },
          timeout: { default: 3600 }
        })
      end
    end

    context 'with multiple local files with duplicate keys' do
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

      it 'raises DuplicateInputError for duplicate key between files' do
        expect { processor.perform }.to raise_error(
          described_class::DuplicateInputError,
          "Duplicate input keys found: database. " \
            "Input keys must be unique across all included files and inline specifications."
        )
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

    context 'when included file contains nested includes' do
      let(:values) do
        {
          include: [{ local: '/inputs-with-include.yml' }],
          inputs: {
            foo: { default: 'bar' }
          }
        }
      end

      let(:project_files) do
        {
          '/inputs-with-include.yml' => <<~YAML
            inputs:
              database:
                default: 'postgres'
            include:
              - local: '/other-inputs.yml'
          YAML
        }
      end

      it 'raises an error about unknown keys' do
        expect { processor.perform }.to raise_error(
          described_class::IncludeError,
          /Header include file .* contains unknown keys: \[:include\]/
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

    context 'with nested input structures without duplicates' do
      let(:values) do
        {
          include: [{ local: '/nested-inputs.yml' }],
          inputs: {
            deployment: {
              default: 'production',
              options: %w[staging production]
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

      it 'merges nested input structures' do
        result = processor.perform
        expect(result[:inputs][:config]).to eq({
          default: 'value',
          options: %w[opt1 opt2]
        })
        expect(result[:inputs][:deployment]).to eq({
          default: 'production',
          options: %w[staging production]
        })
      end
    end

    context 'with nested input structures with duplicate keys' do
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

      it 'raises DuplicateInputError for duplicate nested input key' do
        expect { processor.perform }.to raise_error(
          described_class::DuplicateInputError,
          "Duplicate input keys found: config. " \
            "Input keys must be unique across all included files and inline specifications."
        )
      end
    end

    context 'when duplicate inputs exist across external files' do
      context 'with duplicate between two local files' do
        let(:values) do
          {
            include: [
              { local: '/inputs1.yml' },
              { local: '/inputs2.yml' }
            ]
          }
        end

        let(:project_files) do
          {
            '/inputs1.yml' => <<~YAML,
              inputs:
                environment:
                  default: 'production'
                region:
                  default: 'us-west'
            YAML
            '/inputs2.yml' => <<~YAML
              inputs:
                environment:
                  default: 'staging'
                database:
                  default: 'postgres'
            YAML
          }
        end

        it 'raises DuplicateInputError' do
          expect { processor.perform }.to raise_error(
            described_class::DuplicateInputError,
            "Duplicate input keys found: environment. " \
              "Input keys must be unique across all included files and inline specifications."
          )
        end
      end

      context 'with duplicate between local and remote files' do
        let(:values) do
          {
            include: [
              { local: '/inputs.yml' },
              { remote: 'https://example.com/remote-inputs.yml' }
            ]
          }
        end

        let(:project_files) do
          {
            '/inputs.yml' => <<~YAML
              inputs:
                environment:
                  default: 'production'
                region:
                  default: 'us-west'
            YAML
          }
        end

        let(:remote_file_content) do
          <<~YAML
            inputs:
              environment:
                default: 'staging'
              cache_enabled:
                default: true
          YAML
        end

        before do
          stub_full_request('https://example.com/remote-inputs.yml')
            .to_return(body: remote_file_content)
        end

        it 'raises DuplicateInputError' do
          expect { processor.perform }.to raise_error(
            described_class::DuplicateInputError,
            "Duplicate input keys found: environment. " \
              "Input keys must be unique across all included files and inline specifications."
          )
        end
      end

      context 'with duplicate between local and project files' do
        let(:values) do
          {
            include: [
              { local: '/inputs.yml' },
              {
                project: another_project.full_path,
                file: '/shared-inputs.yml',
                ref: 'master'
              }
            ]
          }
        end

        let(:project_files) do
          {
            '/inputs.yml' => <<~YAML
              inputs:
                environment:
                  default: 'production'
                region:
                  default: 'us-west'
            YAML
          }
        end

        let(:other_project_files) do
          {
            '/shared-inputs.yml' => <<~YAML
              inputs:
                environment:
                  default: 'staging'
                database:
                  default: 'postgres'
            YAML
          }
        end

        before_all do
          another_project.add_developer(user)
        end

        it 'raises DuplicateInputError' do
          expect { processor.perform }.to raise_error(
            described_class::DuplicateInputError,
            "Duplicate input keys found: environment. " \
              "Input keys must be unique across all included files and inline specifications."
          )
        end
      end

      context 'with multiple duplicate keys between files' do
        let(:values) do
          {
            include: [
              { local: '/inputs1.yml' },
              { local: '/inputs2.yml' }
            ]
          }
        end

        let(:project_files) do
          {
            '/inputs1.yml' => <<~YAML,
              inputs:
                environment:
                  default: 'production'
                region:
                  default: 'us-west'
                database:
                  default: 'postgres'
            YAML
            '/inputs2.yml' => <<~YAML
              inputs:
                environment:
                  default: 'staging'
                database:
                  default: 'mysql'
                cache_enabled:
                  default: true
            YAML
          }
        end

        it 'raises DuplicateInputError with all duplicate keys' do
          expect { processor.perform }.to raise_error(
            described_class::DuplicateInputError,
            /Duplicate input keys found: (environment, database|database, environment)\. Input keys must be unique/
          )
        end
      end
    end

    context 'when duplicate inputs exist between external files and inline spec' do
      context 'with single duplicate key' do
        let(:values) do
          {
            include: [{ local: '/inputs.yml' }],
            inputs: {
              environment: { default: 'production' },
              new_input: { default: 'value' }
            }
          }
        end

        let(:project_files) do
          {
            '/inputs.yml' => <<~YAML
              inputs:
                environment:
                  default: 'staging'
                region:
                  default: 'us-west'
            YAML
          }
        end

        it 'raises DuplicateInputError' do
          expect { processor.perform }.to raise_error(
            described_class::DuplicateInputError,
            "Duplicate input keys found: environment. " \
              "Input keys must be unique across all included files and inline specifications."
          )
        end
      end

      context 'with multiple duplicate keys' do
        let(:values) do
          {
            include: [
              { local: '/inputs1.yml' },
              { local: '/inputs2.yml' }
            ],
            inputs: {
              environment: { default: 'production' },
              region: { default: 'us-east' },
              new_input: { default: 'value' }
            }
          }
        end

        let(:project_files) do
          {
            '/inputs1.yml' => <<~YAML,
              inputs:
                environment:
                  default: 'staging'
                database:
                  default: 'postgres'
            YAML
            '/inputs2.yml' => <<~YAML
              inputs:
                region:
                  default: 'us-west'
                cache_enabled:
                  default: true
            YAML
          }
        end

        it 'raises DuplicateInputError with all duplicate keys' do
          expect { processor.perform }.to raise_error(
            described_class::DuplicateInputError,
            /Duplicate input keys found: (environment, region|region, environment)\. Input keys must be unique/
          )
        end
      end

      context 'with all inline keys being duplicates' do
        let(:values) do
          {
            include: [{ local: '/inputs.yml' }],
            inputs: {
              environment: { default: 'production' },
              region: { default: 'us-east' }
            }
          }
        end

        let(:project_files) do
          {
            '/inputs.yml' => <<~YAML
              inputs:
                environment:
                  default: 'staging'
                region:
                  default: 'us-west'
            YAML
          }
        end

        it 'raises DuplicateInputError' do
          expect { processor.perform }.to raise_error(
            described_class::DuplicateInputError,
            /Duplicate input keys found: (environment, region|region, environment)\. Input keys must be unique/
          )
        end
      end
    end

    context 'when no duplicate inputs exist' do
      context 'with multiple external files and inline inputs' do
        let(:values) do
          {
            include: [
              { local: '/inputs1.yml' },
              { local: '/inputs2.yml' }
            ],
            inputs: {
              inline_input: { default: 'value' }
            }
          }
        end

        let(:project_files) do
          {
            '/inputs1.yml' => <<~YAML,
              inputs:
                file1_input:
                  default: 'value1'
                environment:
                  default: 'production'
            YAML
            '/inputs2.yml' => <<~YAML
              inputs:
                file2_input:
                  default: 'value2'
                region:
                  default: 'us-west'
            YAML
          }
        end

        it 'successfully merges all inputs' do
          result = processor.perform
          expect(result[:inputs].keys).to contain_exactly(
            :file1_input, :file2_input, :inline_input, :environment, :region
          )
        end

        it 'preserves all input values correctly' do
          result = processor.perform
          expect(result[:inputs]).to eq({
            file1_input: { default: 'value1' },
            environment: { default: 'production' },
            file2_input: { default: 'value2' },
            region: { default: 'us-west' },
            inline_input: { default: 'value' }
          })
        end
      end

      context 'with only external files and no inline inputs' do
        let(:values) do
          {
            include: [
              { local: '/inputs1.yml' },
              { local: '/inputs2.yml' }
            ]
          }
        end

        let(:project_files) do
          {
            '/inputs1.yml' => <<~YAML,
              inputs:
                environment:
                  default: 'production'
            YAML
            '/inputs2.yml' => <<~YAML
              inputs:
                region:
                  default: 'us-west'
            YAML
          }
        end

        it 'successfully merges all external inputs' do
          result = processor.perform
          expect(result[:inputs]).to eq({
            environment: { default: 'production' },
            region: { default: 'us-west' }
          })
        end
      end

      context 'with only inline inputs and no external files' do
        let(:values) do
          {
            inputs: {
              environment: { default: 'production' },
              region: { default: 'us-west' }
            }
          }
        end

        it 'returns inline inputs unchanged' do
          result = processor.perform
          expect(result[:inputs]).to eq({
            environment: { default: 'production' },
            region: { default: 'us-west' }
          })
        end
      end
    end
  end
end
