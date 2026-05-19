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
                script: echo $[[ inputs.stage | posix_escape ]]
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

    context 'when component uses spec:include' do
      let(:template) do
        <<~YAML
              spec:
                inputs:
                  stage:
                include:
                  - local: /shared-inputs.yml
              ---
              test-my-job:
                stage: $[[ inputs.stage ]]
                script: run tests
        YAML
      end

      it 'does not create a pipeline because spec:include is not supported in components' do
        response = execute_service

        pipeline = response.payload

        expect(pipeline).to be_persisted
        expect(pipeline.error_messages[0].content)
          .to include 'cannot use `spec:include`'
        expect(pipeline.error_messages[0].content)
          .to include 'This keyword is not supported in components'
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

  context 'when including multiple components from the same project' do
    let(:template_a) do
      <<~YAML
        spec:
          inputs:
            stage:
        ---
        component-a-job:
          stage: $[[ inputs.stage ]]
          script: run component a
      YAML
    end

    let(:template_b) do
      <<~YAML
        spec:
          inputs:
            stage:
        ---
        component-b-job:
          stage: $[[ inputs.stage ]]
          script: run component b
      YAML
    end

    let(:template_c) do
      <<~YAML
        spec:
          inputs:
            stage:
        ---
        component-c-job:
          stage: $[[ inputs.stage ]]
          script: run component c
      YAML
    end

    let(:sha) do
      components_project.repository.create_file(
        user,
        'templates/component-a.yml',
        template_a,
        message: 'Add component a',
        branch_name: 'master'
      )

      components_project.repository.create_file(
        user,
        'templates/component-b.yml',
        template_b,
        message: 'Add component b',
        branch_name: 'master'
      )

      components_project.repository.create_file(
        user,
        'templates/component-c.yml',
        template_c,
        message: 'Add component c',
        branch_name: 'master'
      )
    end

    let(:config_one_component) do
      <<~YAML
        include:
          - component: #{Gitlab.config.gitlab.host}/#{components_project.full_path}/component-a@v0.1
            inputs:
              stage: build

        stages:
          - build
      YAML
    end

    let(:config_three_components) do
      <<~YAML
        include:
          - component: #{Gitlab.config.gitlab.host}/#{components_project.full_path}/component-a@v0.1
            inputs:
              stage: build
          - component: #{Gitlab.config.gitlab.host}/#{components_project.full_path}/component-b@v0.1
            inputs:
              stage: test
          - component: #{Gitlab.config.gitlab.host}/#{components_project.full_path}/component-c@v0.1
            inputs:
              stage: deploy

        stages:
          - build
          - test
          - deploy
      YAML
    end

    before do
      components_project.repository.add_tag(user, 'v0.1', sha)
    end

    def execute_service_with_request_store
      Gitlab::SafeRequestStore.ensure_request_store do
        control_count = Gitlab::GitalyClient.get_request_count
        execute_service
        Gitlab::GitalyClient.get_request_count - control_count
      end
    end

    it 'creates a pipeline with jobs from multiple components' do
      stub_ci_pipeline_yaml_file(config_three_components)

      response = execute_service
      pipeline = response.payload

      expect(pipeline).to be_persisted
      expect(pipeline.error_messages).to be_empty
      expect(pipeline.statuses.map(&:name)).to match_array(%w[component-a-job component-b-job component-c-job])
    end

    it 'caches DB calls when including multiple components from the same project', :use_sql_query_cache do
      # Warm up
      stub_ci_pipeline_yaml_file(config_one_component)
      execute_service

      stub_ci_pipeline_yaml_file(config_three_components)
      execute_service

      stub_ci_pipeline_yaml_file(config_one_component)
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        execute_service_with_request_store
      end

      accepted_threshold = 8 # 2 stages + 2 builds + 2 job definitions + 2 build sources
      stub_ci_pipeline_yaml_file(config_three_components)
      expect do
        execute_service_with_request_store
      end.to issue_same_number_of_queries_as(control).with_threshold(accepted_threshold)
    end
  end
end
