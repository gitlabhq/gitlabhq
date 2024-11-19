# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :continuous_integration do
  describe 'creation errors and warnings' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.first_owner }

    let(:ref)      { 'refs/heads/master' }
    let(:source)   { :push }
    let(:service)  { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { service.execute(source).payload }

    before do
      stub_ci_pipeline_yaml_file(config)
    end

    context 'when created successfully' do
      context 'when warnings are raised' do
        let(:config) do
          <<~YAML
            test:
              script: rspec
              rules:
                - when: always
          YAML
        end

        it 'contains only warnings' do
          expect(pipeline.error_messages.map(&:content)).to be_empty

          expect(pipeline.warning_messages.map(&:content)).to contain_exactly(
            /jobs:test may allow multiple pipelines to run/
          )
        end
      end

      context 'when no warnings are raised' do
        let(:config) do
          <<~YAML
            test:
              script: rspec
          YAML
        end

        it 'contains no warnings' do
          expect(pipeline.error_messages).to be_empty

          expect(pipeline.warning_messages).to be_empty
        end
      end
    end

    context 'when failed to create the pipeline' do
      context 'when errors are raised and masked variables are involved' do
        let_it_be(:variable) { create(:ci_variable, project: project, key: 'GL_TOKEN', value: 'test_value', masked: true) }

        let(:config) do
          <<~YAML
          include:
            - local: $GL_TOKEN/gitlab-ci.txt
          YAML
        end

        it 'contains errors and masks variables' do
          error_message = "Included file `[MASKED]xx/gitlab-ci.txt` does not have YAML extension!"
          expect(pipeline.yaml_errors).to eq(error_message)
          expect(pipeline.error_messages.map(&:content)).to contain_exactly(error_message)
          expect(pipeline.errors.full_messages).to contain_exactly(error_message)
        end
      end

      context 'when warnings are raised' do
        let(:config) do
          <<~YAML
            build:
              stage: build
              script: echo
              needs: [test]
            test:
              stage: test
              script: echo
              rules:
                - when: on_success
          YAML
        end

        it 'contains both errors and warnings' do
          error_message = 'build job: need test is not defined in current or prior stages'
          warning_message = /jobs:test may allow multiple pipelines to run/

          expect(pipeline.yaml_errors).to eq(error_message)
          expect(pipeline.error_messages.map(&:content)).to contain_exactly(error_message)
          expect(pipeline.errors.full_messages).to contain_exactly(error_message)

          expect(pipeline.warning_messages.map(&:content)).to contain_exactly(warning_message)
        end
      end

      context 'when no warnings are raised' do
        let(:config) do
          <<~YAML
            invalid: yaml
          YAML
        end

        it 'contains only errors' do
          error_message = 'jobs invalid config should implement the script:, run:, or trigger: keyword'
          expect(pipeline.yaml_errors).to eq(error_message)
          expect(pipeline.error_messages.map(&:content)).to contain_exactly(error_message)
          expect(pipeline.errors.full_messages).to contain_exactly(error_message)

          expect(pipeline.warning_messages).to be_empty
        end
      end
    end
  end
end
