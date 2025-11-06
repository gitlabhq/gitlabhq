# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a pipeline that includes CI components', feature_category: :pipeline_composition do
  let_it_be_with_refind(:project) { create(:project, :repository) }
  let_it_be_with_reload(:user) { project.first_owner }

  let(:components_project) do
    create(:project, :repository, creator: user, namespace: user.namespace)
  end

  let(:component_path) do
    "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/my-component@v0.1"
  end

  let(:template) do
    <<~YAML
          spec:
            inputs:
              stage:
              suffix:
                default: my-job
          ---
          test-$[[ inputs.suffix ]]:
            stage: $[[ inputs.stage ]]
            script: run tests
    YAML
  end

  let(:sha) do
    components_project.repository.create_file(
      user,
      'templates/my-component/template.yml',
      template,
      message: 'Add my first CI component',
      branch_name: 'master'
    )
  end

  let(:config) do
    <<~YAML
          include:
            - component: #{component_path}
              inputs:
                stage: my-stage

          stages:
            - my-stage

          test-1:
            stage: my-stage
            script: run test-1
    YAML
  end

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  context 'when there is no version with specified tag' do
    before do
      components_project.repository.add_tag(user, 'v0.01', sha)
    end

    it 'does not create a pipeline' do
      response = execute_service

      pipeline = response.payload

      expect(pipeline).to be_persisted
      expect(pipeline.error_messages[0].content)
        .to include "my-component@v0.1' - content not found"
    end
  end

  context 'when there is a proper revision available' do
    before do
      components_project.repository.add_tag(user, 'v0.1', sha)
    end

    context 'when component is valid' do
      it 'creates a pipeline using a pipeline component' do
        response = execute_service

        pipeline = response.payload

        expect(pipeline).to be_persisted
        expect(pipeline.error_messages).to be_empty
        expect(pipeline.statuses.count).to eq 2
        expect(pipeline.statuses.map(&:name)).to match_array %w[test-1 test-my-job]
      end
    end

    context 'when interpolation is invalid' do
      let(:template) do
        <<~YAML
              spec:
                inputs:
                  stage:
              ---
              test:
                stage: $[[ inputs.stage ]]
                script: rspec --suite $[[ inputs.suite ]]
        YAML
      end

      it 'does not create a pipeline' do
        response = execute_service

        pipeline = response.payload

        expect(pipeline).to be_persisted
        expect(pipeline.error_messages[0].content)
          .to include 'unknown interpolation provided: `suite`'
      end
    end

    context 'when there is a syntax error in the template' do
      let(:template) do
        <<~YAML
              spec:
                inputs:
                  stage:
              ---
              :test
                stage: $[[ inputs.stage ]]
        YAML
      end

      it 'does not create a pipeline' do
        response = execute_service

        pipeline = response.payload

        expect(pipeline).to be_persisted
        expect(pipeline.error_messages[0].content)
          .to include 'mapping values are not allowed'
      end
    end

    context 'when an existing interpolation function is used in the template' do
      let(:template) do
        <<~YAML
              spec:
                inputs:
                  stage:
              ---
              test-my-job:
                stage: $[[ inputs.stage ]]
                script: echo $[[ inputs.stage | posix_quote ]]
        YAML
      end

      it 'creates a pipeline using a pipeline component' do
        response = execute_service

        pipeline = response.payload

        expect(pipeline).to be_persisted
        expect(pipeline.error_messages).to be_empty
        expect(pipeline.statuses.count).to eq 2
        expect(pipeline.statuses.map(&:name)).to match_array %w[test-1 test-my-job]
      end
    end

    context 'when an undefined interpolation function is used in the template' do
      let(:template) do
        <<~YAML
              spec:
                inputs:
                  stage:
              ---
              test-my-job:
                stage: $[[ inputs.stage ]]
                script: echo $[[ inputs.stage | gitlab_undefined_function ]]
        YAML
      end

      it 'does not create a pipeline' do
        response = execute_service

        pipeline = response.payload

        expect(pipeline).to be_persisted
        expect(pipeline.error_messages[0].content)
          .to include 'no function matching `gitlab_undefined_function`:'
      end
    end
  end

  def execute_service
    ::Ci::CreatePipelineService
      .new(project, user, { ref: project.default_branch })
      .execute(:push, save_on_errors: true) do |pipeline|
      yield(pipeline) if block_given?
    end
  end
end
