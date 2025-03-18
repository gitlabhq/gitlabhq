# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }

  let(:ref) { 'refs/heads/master' }
  let(:service) { described_class.new(project, user, { ref: ref }) }

  subject(:execute) { service.execute(:push, linting: true).payload }

  before do
    stub_ci_pipeline_yaml_file(config)
  end

  describe 'linting' do
    shared_examples 'returns a non persisted pipeline' do
      it 'does not persist the pipeline' do
        expect(execute).not_to be_persisted
        expect(execute.id).to be_nil
      end
    end

    context 'when pipeline is valid' do
      let(:config) { gitlab_ci_yaml }

      it_behaves_like 'returns a non persisted pipeline'

      it 'returns a valid pipeline' do
        expect(execute.error_messages).to be_empty
        expect(execute.yaml_errors).to be_nil
        expect(execute.errors).to be_empty
      end
    end

    context 'when pipeline is not valid' do
      context 'when there are syntax errors' do
        let(:config) do
          <<~YAML
            rspec:
              script: echo
              something: wrong
          YAML
        end

        it_behaves_like 'returns a non persisted pipeline'

        it 'returns a pipeline with errors' do
          error_message = 'jobs:rspec config contains unknown keys: something'

          expect(execute.error_messages.map(&:content)).to eq([error_message])
          expect(execute.errors).not_to be_empty
        end
      end

      context 'when there are logical errors' do
        let(:config) do
          <<~YAML
            build:
              script: echo
              stage: build
              needs: [test]
            test:
              script: echo
              stage: test
          YAML
        end

        it_behaves_like 'returns a non persisted pipeline'

        it 'returns a pipeline with errors' do
          error_message = 'build job: need test is not defined in current or prior stages'

          expect(execute.error_messages.map(&:content)).to eq([error_message])
          expect(execute.errors).not_to be_empty
        end
      end

      context 'when there are errors at the seeding stage' do
        let(:config) do
          <<~YAML
            build:
              stage: build
              script: echo
              rules:
                - if: '$CI_MERGE_REQUEST_ID'
            test:
              stage: test
              script: echo
              needs: ['build']
          YAML
        end

        it_behaves_like 'returns a non persisted pipeline'

        it 'returns a valid pipeline' do
          expect(execute.error_messages).to be_empty
          expect(execute.yaml_errors).to be_nil
          expect(execute.errors).to be_empty
        end
      end
    end
  end
end
