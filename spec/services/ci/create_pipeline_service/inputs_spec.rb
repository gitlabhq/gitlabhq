# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :pipeline_composition do
  include RepoHelpers

  context 'for inputs' do
    let_it_be(:project) { create(:project, :small_repo) }
    let_it_be(:user)    { project.first_owner }

    let(:ref)    { 'refs/heads/master' }
    let(:source) { :push }
    let(:content) { nil }
    let(:inputs) { {} }

    let_it_be(:complex_inputs_example_path) { 'spec/lib/gitlab/ci/config/yaml/fixtures/complex-included-ci.yml' }
    let_it_be(:complex_inputs_example_yaml) { File.read(Rails.root.join(complex_inputs_example_path)) }

    let(:project_ci_config_path) { nil } # default: .gitlab-ci.yml

    let(:service) { described_class.new(project, user, { ref: ref }) }

    subject(:execute) { service.execute(source, content: content, inputs: inputs) }

    before do
      project.ci_config_path = project_ci_config_path
    end

    shared_examples 'returning errors' do
      it 'returns errors' do
        response = execute
        pipeline = response.payload

        expect(response).to be_error

        errors = pipeline.error_messages.map(&:content)

        expect(errors.size).to eq(1)
        expected_errors.each do |error|
          expect(errors.first).to include(error)
        end
      end
    end

    shared_examples 'testing invalid and valid cases' do
      context 'when passing no inputs' do
        let(:expected_errors) do
          [
            '`deploy_strategy` input: required value has not been provided',
            '`job_stage` input: required value has not been provided',
            '`test_script` input: required value has not been provided'
          ]
        end

        it_behaves_like 'returning errors'
      end

      context 'when passing invalid inputs' do
        let(:inputs) do
          {
            deploy_strategy: 'manual',
            job_stage: 'deploy',
            test_script: 'echo "test"'
          }
        end

        let(:expected_errors) do
          [
            '`deploy_strategy` input: `manual` cannot be used because it is not in the list of allowed options',
            '`test_script` input: provided value is not an array'
          ]
        end

        it_behaves_like 'returning errors'
      end

      context 'when passing valid inputs' do
        let(:inputs) do
          {
            deploy_strategy: 'blue-green',
            job_stage: 'deploy',
            test_script: ['echo "test"'],
            test_rules: [
              { if: '$CI_PIPELINE_SOURCE == "push"' }
            ],
            test_framework: '$TEST_FRAMEWORK'
          }
        end

        before_all do
          create(:ci_variable, project: project, key: 'TEST_FRAMEWORK', value: 'rspec')
        end

        it 'creates a pipeline with correct jobs' do
          response = execute
          pipeline = response.payload

          expect(response).to be_success
          expect(pipeline).to be_created_successfully

          expect(pipeline.builds.map(&:name)).to contain_exactly(
            'my-job-build 1/2', 'my-job-build 2/2', 'my-job-test', 'my-job-test-2', 'my-job-deploy'
          )
          expect(pipeline.builds.map(&:stage)).to contain_exactly('deploy', 'deploy', 'deploy', 'deploy', 'deploy')

          my_job_test = pipeline.builds.find { |build| build.name == 'my-job-test' }
          expect(my_job_test.options[:script]).to eq([
            'echo "Testing with rspec"',
            'if [ false == true ]; then echo "Coverage is enabled"; fi'
          ])

          my_job_test_2 = pipeline.builds.find { |build| build.name == 'my-job-test-2' }
          expect(my_job_test_2.options[:script]).to eq(['echo "test"'])

          my_job_deploy = pipeline.builds.find { |build| build.name == 'my-job-deploy' }
          expect(my_job_deploy.options[:script]).to eq(['echo "Deploying to staging using blue-green strategy"'])
        end

        it 'tracks the usage of inputs' do
          expect { execute }.to trigger_internal_events('create_pipeline_with_inputs').with(
            category: 'Gitlab::Ci::Pipeline::Chain::Metrics',
            additional_properties: { value: 5, label: 'push', property: config_source },
            project: project,
            user: user
          )
        end

        context 'when the FF ci_inputs_for_pipelines is disabled' do
          before do
            stub_feature_flags(ci_inputs_for_pipelines: false)
          end

          let(:expected_errors) do
            [
              '`deploy_strategy` input: required value has not been provided',
              '`job_stage` input: required value has not been provided',
              '`test_script` input: required value has not been provided'
            ]
          end

          it_behaves_like 'returning errors'
        end
      end
    end

    context 'when the project CI config is in the current repository file' do
      let(:config_source) { 'repository_source' }

      let(:project_files) do
        { '.gitlab-ci.yml' => complex_inputs_example_yaml }
      end

      around do |example|
        create_and_delete_files(project, project_files) do
          example.run
        end
      end

      it_behaves_like 'testing invalid and valid cases'
    end

    context 'when the project CI config is in another project repository file' do
      let(:config_source) { 'external_project_source' }

      let_it_be(:project_2) do
        create(:project, :custom_repo, files: { 'a_config_file.yml' => complex_inputs_example_yaml })
      end

      let(:project_ci_config_path) { "a_config_file.yml@#{project_2.full_path}:#{project_2.default_branch}" }

      before_all do
        project_2.add_developer(user)
      end

      it_behaves_like 'testing invalid and valid cases'
    end

    context 'when the project CI config is a remote file' do
      let(:config_source) { 'remote_source' }

      let(:project_ci_config_path) { 'https://gitlab.example.com/something/.gitlab-ci.yml' }

      before do
        stub_request(:get, project_ci_config_path)
          .to_return(status: 200, body: complex_inputs_example_yaml)
      end

      it_behaves_like 'testing invalid and valid cases'
    end

    context 'when the CI config is passed as content' do
      let(:config_source) { 'parameter_source' }

      let(:content) { complex_inputs_example_yaml }

      it_behaves_like 'testing invalid and valid cases'
    end

    context 'when the CI config does not have spec:inputs' do
      let(:content) do
        <<~YAML
          job:
            script: echo "hello"
        YAML
      end

      context 'when passing inputs' do
        let(:inputs) do
          { deploy_strategy: 'blue-green' }
        end

        let(:expected_errors) do
          ['Given inputs not defined in the `spec` section of the included configuration file']
        end

        it_behaves_like 'returning errors'

        context 'when the FF ci_inputs_for_pipelines is disabled' do
          before do
            stub_feature_flags(ci_inputs_for_pipelines: false)
          end

          it 'creates a pipeline' do
            response = execute
            pipeline = response.payload

            expect(response).to be_success
            expect(pipeline).to be_created_successfully

            expect(pipeline.builds.map(&:name)).to contain_exactly('job')
          end
        end
      end
    end
  end
end
