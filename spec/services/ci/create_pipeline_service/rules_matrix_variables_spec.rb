# frozen_string_literal: true

require 'spec_helper'

# This spec file documents and tests the behavior of matrix variables in rules keywords.
#
# Matrix variables are available in all rules keywords - each job instance evaluates
# rules using its own matrix variable values.
#
# Nested expansion (when a matrix variable value itself references another variable,
# e.g. FILE: $GLOBAL_FILE):
#   - rules:changes and rules:exists: the nested reference IS resolved (via variables_hash_expanded)
#   - rules:if: the nested reference is NOT resolved (uses variables_hash)

# rubocop:disable RSpec/SpecFilePathFormat -- More descriptive filename than create_pipeline_service_rules_matrix_variables_spec.rb
RSpec.describe Ci::CreatePipelineService, feature_category: :pipeline_composition do
  # rubocop:enable RSpec/SpecFilePathFormat
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:ref) { 'refs/heads/master' }
  let(:source) { :push }
  let(:before_sha) { project.commit(ref).parent_id }
  let(:after_sha) { project.commit(ref).sha }
  let(:service) { described_class.new(project, user, { ref: ref, before: before_sha, after: after_sha }) }
  let(:response) { service.execute(source) }
  let(:pipeline) { response.payload }
  let(:project_files) { {} }

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  around do |example|
    if project_files.any?
      create_and_delete_files(project, project_files) { example.run }
    else
      example.run
    end
  end

  describe 'rules:changes with matrix variables' do
    context 'when using simple matrix variable in changes' do
      let(:project_files) { { 'file1.txt' => 'content' } }
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $FILE"
              parallel:
                matrix:
                  - FILE: [file1.txt, file2.txt, file3.txt]
              rules:
                - if: $CI_PIPELINE_SOURCE == "push"
                  changes:
                    - $FILE
        YAML
      end

      it 'creates only the job for the changed file' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [file1.txt]')
      end
    end

    context 'when using matrix variable in changes with glob pattern' do
      let(:project_files) { { 'components/frontend/src/app.js' => 'code' } }
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $COMPONENT"
              parallel:
                matrix:
                  - COMPONENT: [frontend, backend, database]
              rules:
                - if: $CI_PIPELINE_SOURCE == "push"
                  changes:
                    - components/$COMPONENT/**/*
        YAML
      end

      it 'creates only the job for the component with changes' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [frontend]')
      end
    end

    context 'when using matrix variable with if:changes combination' do
      let(:project_files) { { 'config.yml' => 'config' } }
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $FILE"
              parallel:
                matrix:
                  - FILE: [config.yml, data.json]
              rules:
                - if: $CI_PIPELINE_SOURCE == "push"
                  changes:
                    - $FILE
        YAML
      end

      it 'evaluates both if condition and changes' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [config.yml]')
      end
    end

    context 'when using multiple matrix variables in changes' do
      let(:project_files) { { 'config/dev/us/app.yml' => 'config' } }
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $ENV in $REGION"
              parallel:
                matrix:
                  - ENV: [dev, prod]
                    REGION: [us, eu]
              rules:
                - if: $CI_PIPELINE_SOURCE == "push"
                  changes:
                    - config/$ENV/$REGION/**/*
        YAML
      end

      it 'creates only the job matching both variables' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [dev, us]')
      end
    end

    context 'when matrix variable is used with regular variable in changes' do
      let(:project_files) { { 'src/auth/login.rb' => 'code' } }
      let(:config) do
        <<~YAML
            variables:
              BASE_PATH: src

            test:
              script: echo "Testing $MODULE"
              parallel:
                matrix:
                  - MODULE: [auth, billing, reports]
              rules:
                - changes:
                    - $BASE_PATH/$MODULE/**/*
        YAML
      end

      it 'expands both regular and matrix variables' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [auth]')
      end
    end

    context 'when matrix variable value references another variable' do
      let(:project_files) { { 'nested_expansion_test.txt' => 'content' } }
      let(:config) do
        <<~YAML
            variables:
              GLOBAL_FILE: 'nested_expansion_test.txt'

            test:
              script: echo "Testing $FILE"
              parallel:
                matrix:
                  - FILE: $GLOBAL_FILE
              rules:
                - changes:
                    - $FILE
        YAML
      end

      it 'resolves the nested reference when evaluating the changes path' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [$GLOBAL_FILE]')
      end
    end
  end

  describe 'rules:exists with matrix variables' do
    context 'when using simple matrix variable in exists' do
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $FILE"
              parallel:
                matrix:
                  - FILE: [README.md, NONEXISTENT.txt, MISSING.yml]
              rules:
                - exists:
                    - $FILE
        YAML
      end

      it 'creates only matching job' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [README.md]')
      end
    end

    context 'when using matrix variable in exists with glob pattern' do
      let(:project_files) { { 'main.go' => 'package main' } }
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $TYPE"
              parallel:
                matrix:
                  - TYPE: [go, ruby, python]
              rules:
                - exists:
                    - "**/*.$TYPE"
        YAML
      end

      it 'creates only the job for the type with matching file' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [go]')
      end
    end

    context 'when combining if condition with exists using matrix variable' do
      let(:project_files) { { 'test.txt' => 'test content' } }
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $FILE"
              parallel:
                matrix:
                  - FILE: [test.txt, prod.txt]
              rules:
                - if: $CI_PIPELINE_SOURCE == "push"
                  exists:
                    - $FILE
        YAML
      end

      it 'evaluates both if condition and exists' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [test.txt]')
      end
    end

    context 'when using multiple matrix variables in exists' do
      let(:project_files) { { 'deployments/api/test/config.yml' => 'service: api' } }
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $SERVICE in $ENV"
              parallel:
                matrix:
                  - SERVICE: [api, web]
                    ENV: [test, prod]
              rules:
                - exists:
                    - deployments/$SERVICE/$ENV/config.yml
        YAML
      end

      it 'creates only the job matching both variables' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [api, test]')
      end
    end

    context 'when matrix variable is used with regular variable in exists' do
      let(:project_files) { { 'src/auth/init.rb' => 'code' } }
      let(:config) do
        <<~YAML
            variables:
              BASE_PATH: src

            test:
              script: echo "Testing $MODULE"
              parallel:
                matrix:
                  - MODULE: [auth, billing, reports]
              rules:
                - exists:
                    - $BASE_PATH/$MODULE/**/*
        YAML
      end

      it 'expands both regular and matrix variables' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [auth]')
      end
    end

    context 'when matrix variable value references another variable' do
      let(:config) do
        <<~YAML
            variables:
              GLOBAL_FILE: 'README.md'

            test:
              script: echo "Testing $FILE"
              parallel:
                matrix:
                  - FILE: $GLOBAL_FILE
              rules:
                - exists:
                    - $FILE
        YAML
      end

      it 'resolves the nested reference when evaluating the exists path' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [$GLOBAL_FILE]')
      end
    end
  end

  describe 'rules:if with matrix variables' do
    context 'when trying to use matrix variable in if condition' do
      let(:config) do
        <<~YAML
            test:
              script: echo "Building $ARCH"
              parallel:
                matrix:
                  - ARCH: [amd64, arm64]
                    SKIP: ["false", "true"]
              rules:
                - if: $SKIP == "true"
                  when: never
                - when: on_success
        YAML
      end

      it 'filters jobs by matrix variable value' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly(
          'test: [amd64, false]',
          'test: [arm64, false]'
        )
      end
    end

    context 'when using regex match with matrix variable in if condition' do
      let(:config) do
        <<~YAML
            test:
              script: echo "Building $ARCH"
              parallel:
                matrix:
                  - ARCH: [amd64, arm64, arm32]
              rules:
                - if: $ARCH =~ /arm/
        YAML
      end

      it 'creates only jobs whose matrix variable value matches the regex' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly(
          'test: [arm64]',
          'test: [arm32]'
        )
      end
    end

    context 'when using multiple matrix variables in if expression' do
      let(:config) do
        <<~YAML
            test:
              script: echo "Building $ARCH"
              parallel:
                matrix:
                  - ARCH: [amd64, arm64]
                    SKIP: ["false", "true"]
              rules:
                - if: $ARCH == "amd64" && $SKIP == "false"
        YAML
      end

      it 'creates only the job matching both matrix variable conditions' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [amd64, false]')
      end
    end

    context 'when combining matrix variable with regular CI variable in if condition' do
      let(:config) do
        <<~YAML
            test:
              script: echo "Testing $MODULE"
              parallel:
                matrix:
                  - MODULE: [frontend, backend]
              rules:
                - if: $CI_PIPELINE_SOURCE == "push" && $MODULE == "frontend"
        YAML
      end

      it 'evaluates both the CI variable and the matrix variable' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly('test: [frontend]')
      end
    end

    context 'when matrix variable value references another variable' do
      let(:config) do
        <<~YAML
            variables:
              GLOBAL_SKIP: "true"

            test:
              script: echo "Building $ARCH"
              parallel:
                matrix:
                  - ARCH: [amd64, arm64]
                    SKIP: $GLOBAL_SKIP
              rules:
                - if: $SKIP == "true"
                  when: never
                - when: on_success
        YAML
      end

      it 'does not resolve the nested reference, so the condition does not match' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.pluck(:name)).to contain_exactly(
          'test: [amd64, $GLOBAL_SKIP]',
          'test: [arm64, $GLOBAL_SKIP]'
        )
      end
    end
  end
end
