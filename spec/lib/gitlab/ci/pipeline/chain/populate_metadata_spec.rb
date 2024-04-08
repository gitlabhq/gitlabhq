# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::PopulateMetadata, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_pipeline, project: project, ref: 'master', user: user)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master')
  end

  let(:dependencies) do
    [
      Gitlab::Ci::Pipeline::Chain::Config::Content.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Config::Process.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::SeedBlock.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Seed.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Populate.new(pipeline, command)
    ]
  end

  let(:step) { described_class.new(pipeline, command) }

  let(:config) do
    { rspec: { script: 'rspec' } }
  end

  def run_chain
    dependencies.map(&:perform!)
    step.perform!
  end

  before do
    stub_ci_pipeline_yaml_file(YAML.dump(config))
  end

  shared_examples 'not breaking the chain' do
    it 'does not break the chain' do
      run_chain

      expect(step.break?).to be false
    end
  end

  shared_examples 'not saving pipeline metadata' do
    it 'does not save pipeline metadata' do
      run_chain

      expect(pipeline.pipeline_metadata).to be_nil
    end
  end

  context 'with pipeline name' do
    let(:config) do
      { workflow: { name: ' Pipeline name  ' }, rspec: { script: 'rspec' } }
    end

    it_behaves_like 'not breaking the chain'

    it 'builds pipeline_metadata' do
      run_chain

      expect(pipeline.pipeline_metadata.name).to eq('Pipeline name')
      expect(pipeline.pipeline_metadata.project).to eq(pipeline.project)
      expect(pipeline.pipeline_metadata).not_to be_persisted
    end

    context 'with empty name' do
      let(:config) do
        { workflow: { name: '  ' }, rspec: { script: 'rspec' } }
      end

      it_behaves_like 'not saving pipeline metadata'

      context 'with empty name after variable substitution' do
        let(:config) do
          { workflow: { name: '$VAR1' }, rspec: { script: 'rspec' } }
        end

        it_behaves_like 'not saving pipeline metadata'
      end
    end

    context 'with variables' do
      let(:config) do
        {
          variables: { ROOT_VAR: 'value $WORKFLOW_VAR1' },
          workflow: {
            name: 'Pipeline $ROOT_VAR $WORKFLOW_VAR2 $UNKNOWN_VAR',
            rules: [{ variables: { WORKFLOW_VAR1: 'value1', WORKFLOW_VAR2: 'value2' } }]
          },
          rspec: { script: 'rspec' }
        }
      end

      it 'substitutes variables' do
        run_chain

        expect(pipeline.pipeline_metadata.name).to eq('Pipeline value value1 value2')
      end
    end

    context 'with invalid name' do
      let(:config) do
        {
          variables: { ROOT_VAR: 'a' * 256 },
          workflow: {
            name: 'Pipeline $ROOT_VAR'
          },
          rspec: { script: 'rspec' }
        }
      end

      it 'returns error and breaks chain' do
        ret = run_chain

        expect(ret)
          .to match_array(["Failed to build pipeline metadata! Name is too long (maximum is 255 characters)"])
        expect(pipeline.pipeline_metadata.errors.full_messages)
          .to match_array(['Name is too long (maximum is 255 characters)'])
        expect(step.break?).to be true
      end
    end
  end

  context 'with auto_cancel' do
    let(:on_new_commit) { 'interruptible' }
    let(:on_job_failure) { 'all' }
    let(:auto_cancel) { { on_new_commit: on_new_commit, on_job_failure: on_job_failure } }
    let(:config) { { workflow: { auto_cancel: auto_cancel }, rspec: { script: 'rspec' } } }

    it_behaves_like 'not breaking the chain'

    it 'builds pipeline_metadata' do
      run_chain

      expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('interruptible')
      expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('all')
      expect(pipeline.pipeline_metadata).not_to be_persisted
    end

    context 'with no auto_cancel' do
      let(:config) do
        { rspec: { script: 'rspec' } }
      end

      it_behaves_like 'not saving pipeline metadata'
    end

    context 'with auto_cancel: nil' do
      let(:auto_cancel) { nil }

      it_behaves_like 'not saving pipeline metadata'
    end

    context 'with auto_cancel_on_new_commit and no auto_cancel_on_job_failure' do
      let(:auto_cancel) { { on_new_commit: on_new_commit } }

      it 'builds pipeline_metadata' do
        run_chain

        expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('interruptible')
        expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('none')
        expect(pipeline.pipeline_metadata).not_to be_persisted
      end
    end

    context 'with auto_cancel_on_job_failure and no auto_cancel_on_new_commit' do
      let(:auto_cancel) { { on_job_failure: on_job_failure } }

      it 'builds pipeline_metadata' do
        run_chain

        expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('conservative')
        expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('all')
        expect(pipeline.pipeline_metadata).not_to be_persisted
      end
    end

    context 'with auto_cancel_on_new_commit: nil and auto_cancel_on_job_failure: nil' do
      let(:on_new_commit) { nil }
      let(:on_job_failure) { nil }

      it_behaves_like 'not saving pipeline metadata'
    end

    context 'with auto_cancel_on_new_commit valid and auto_cancel_on_job_failure: nil' do
      let(:on_job_failure) { nil }

      it 'builds pipeline_metadata' do
        run_chain

        expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('interruptible')
        expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('none')
        expect(pipeline.pipeline_metadata).not_to be_persisted
      end
    end

    context 'with auto_cancel_on_new_commit: nil and auto_cancel_on_job_failure valid' do
      let(:on_new_commit) { nil }

      it 'builds pipeline_metadata' do
        run_chain

        expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('conservative')
        expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('all')
        expect(pipeline.pipeline_metadata).not_to be_persisted
      end
    end

    context 'when auto_cancel_on_job_failure: none' do
      let(:on_job_failure) { 'none' }

      it 'builds pipeline_metadata' do
        run_chain

        expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('none')
        expect(pipeline.pipeline_metadata).not_to be_persisted
      end
    end

    context 'with workflow:rules:auto_cancel' do
      context 'with auto_cancel:on_new_commit not set and rules:workflow:auto_cancel:on_new_commit set' do
        let(:config) do
          {
            variables: { MY_VAR: my_var_value },
            workflow: {
              auto_cancel: { on_job_failure: 'all' },
              rules: [{ if: '$MY_VAR == "something"', auto_cancel: { on_new_commit: 'interruptible' } }]
            },
            rspec: { script: 'rspec' }
          }
        end

        context 'when the rule is matched' do
          let(:my_var_value) { 'something' }

          it 'builds pipeline_metadata' do
            run_chain

            expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('interruptible')
            expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('all')
          end
        end

        context 'when the rule is not matched' do
          let(:my_var_value) { 'something else' }

          it 'builds pipeline_metadata' do
            run_chain

            expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('conservative')
            expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('all')
          end
        end
      end

      context 'with auto_cancel:on_new_commit set and rules:workflow:auto_cancel:on_new_commit set' do
        let(:config) do
          {
            variables: { MY_VAR: my_var_value },
            workflow: {
              auto_cancel: { on_new_commit: 'interruptible' },
              rules: [{ if: '$MY_VAR == "something"', auto_cancel: { on_new_commit: 'none' } }]
            },
            rspec: { script: 'rspec' }
          }
        end

        context 'when the rule is matched' do
          let(:my_var_value) { 'something' }

          it 'builds pipeline_metadata' do
            run_chain

            expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('none')
            expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('none')
          end
        end

        context 'when the rule is not matched' do
          let(:my_var_value) { 'something else' }

          it 'builds pipeline_metadata' do
            run_chain

            expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('interruptible')
            expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('none')
          end
        end
      end
    end
  end

  context 'with both pipeline name and auto_cancel' do
    let(:config) do
      {
        workflow: {
          name: 'Pipeline name',
          auto_cancel: {
            on_new_commit: 'interruptible',
            on_job_failure: 'none'
          }
        },
        rspec: { script: 'rspec' }
      }
    end

    it_behaves_like 'not breaking the chain'

    it 'builds pipeline_metadata' do
      run_chain

      expect(pipeline.pipeline_metadata.name).to eq('Pipeline name')
      expect(pipeline.pipeline_metadata.auto_cancel_on_new_commit).to eq('interruptible')
      expect(pipeline.pipeline_metadata.auto_cancel_on_job_failure).to eq('none')
      expect(pipeline.pipeline_metadata).not_to be_persisted
    end
  end
end
