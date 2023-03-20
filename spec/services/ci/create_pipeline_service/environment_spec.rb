# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :yaml_processor_feature_flag_corectness,
  feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user) }

  let(:service) { described_class.new(project, user, ref: 'master') }
  let(:user) { developer }

  before_all do
    project.add_developer(developer)
  end

  describe '#execute' do
    subject { service.execute(:push).payload }

    context 'with deployment tier' do
      before do
        config = YAML.dump(
          deploy: {
            script: 'ls',
            environment: { name: "review/$CI_COMMIT_REF_NAME", deployment_tier: tier }
          })

        stub_ci_pipeline_yaml_file(config)
      end

      let(:tier) { 'development' }

      it 'creates the environment with the expected tier' do
        is_expected.to be_created_successfully

        expect(Environment.find_by_name("review/master")).to be_development
      end

      context 'when tier is testing' do
        let(:tier) { 'testing' }

        it 'creates the environment with the expected tier' do
          is_expected.to be_created_successfully

          expect(Environment.find_by_name("review/master")).to be_testing
        end
      end
    end

    context 'when branch pipeline creates a dynamic environment' do
      before do
        config = YAML.dump(
          review_app: {
            script: 'echo',
            environment: { name: "review/$CI_COMMIT_REF_NAME" }
          })

        stub_ci_pipeline_yaml_file(config)
      end

      it 'does not associate merge request with the environment' do
        is_expected.to be_created_successfully

        expect(Environment.find_by_name('review/master').merge_request).to be_nil
      end
    end

    context 'when variables are dependent on stage name' do
      let(:config) do
        <<~YAML
          deploy-review-app-1:
            stage: deploy
            environment: 'test/$CI_JOB_STAGE/1'
            script:
              - echo $SCOPED_VARIABLE
            rules:
              - if: $SCOPED_VARIABLE == 'my-value-1'

          deploy-review-app-2:
            stage: deploy
            script:
              - echo $SCOPED_VARIABLE
            environment: 'test/$CI_JOB_STAGE/2'
            rules:
              - if: $SCOPED_VARIABLE == 'my-value-2'
        YAML
      end

      before do
        create(:ci_variable, key: 'SCOPED_VARIABLE', value: 'my-value-1', environment_scope: '*', project: project)
        create(:ci_variable,
          key: 'SCOPED_VARIABLE',
          value: 'my-value-2',
          environment_scope: 'test/deploy/*',
          project: project
        )
        stub_ci_pipeline_yaml_file(config)
      end

      it 'creates the pipeline successfully', :aggregate_failures do
        pipeline = subject
        build = pipeline.builds.first

        expect(pipeline).to be_created_successfully
        expect(Environment.find_by_name('test/deploy/2')).to be_persisted
        expect(pipeline.builds.size).to eq(1)
        expect(build.persisted_environment.name).to eq('test/deploy/2')
        expect(build.name).to eq('deploy-review-app-2')
        expect(build.environment).to eq('test/$CI_JOB_STAGE/2')
        expect(build.variables.to_hash['SCOPED_VARIABLE']).to eq('my-value-2')
      end
    end
  end
end
