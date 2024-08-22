# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Populate, feature_category: :pipeline_composition do
  include Ci::PipelineMessageHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_pipeline, project: project, ref: 'master', user: user)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master',
      seeds_block: nil)
  end

  let(:dependencies) do
    [
      Gitlab::Ci::Pipeline::Chain::Config::Content.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Config::Process.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::EvaluateWorkflowRules.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::SeedBlock.new(pipeline, command),
      Gitlab::Ci::Pipeline::Chain::Seed.new(pipeline, command)
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

  context 'when pipeline doesn not have seeds block' do
    before do
      run_chain
    end

    it 'does not persist the pipeline' do
      expect(pipeline).not_to be_persisted
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'populates pipeline with stages' do
      expect(pipeline.stages).to be_one
      expect(pipeline.stages.first).not_to be_persisted
      expect(pipeline.stages.first.statuses).to be_one
      expect(pipeline.stages.first.statuses.first).not_to be_persisted
    end

    it 'correctly assigns user' do
      expect(pipeline.builds).to all(have_attributes(user: user))
    end

    it 'has pipeline iid' do
      expect(pipeline.iid).to be > 0
    end
  end

  context 'when pipeline is empty' do
    let(:config) do
      { rspec: {
        script: 'ls',
        only: ['something']
      } }
    end

    before do
      run_chain
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'appends an error about missing stages' do
      expect(pipeline.errors.to_a)
        .to include sanitize_message(::Ci::Pipeline.rules_failure_message)
    end

    it 'wastes pipeline iid' do
      expect(InternalId.ci_pipelines.where(project_id: project.id).last.last_value).to be > 0
    end

    it 'increments the error metric' do
      counter = Gitlab::Metrics.counter(:gitlab_ci_pipeline_failure_reasons, 'desc')
      expect { run_chain }.to change { counter.get(reason: 'filtered_by_rules') }.by(1)
    end

    it 'sets the failure reason without persisting the pipeline', :aggregate_failures do
      run_chain

      expect(pipeline).not_to be_persisted
      expect(pipeline).to be_failed
      expect(pipeline).to be_filtered_by_rules
    end
  end

  describe 'pipeline protect' do
    context 'when ref is protected' do
      before do
        allow(project).to receive(:protected_for?).with('master').and_return(true)
        allow(project).to receive(:protected_for?).with('refs/heads/master').and_return(true)

        dependencies.map(&:perform!)
      end

      it 'does not protect the pipeline' do
        run_chain

        expect(pipeline.protected).to eq(true)
      end
    end

    context 'when ref is not protected' do
      it 'does not protect the pipeline' do
        run_chain

        expect(pipeline.protected).to eq(false)
      end
    end
  end

  context 'when pipeline has validation errors' do
    let(:pipeline) do
      build(:ci_pipeline, project: project, ref: nil)
    end

    before do
      run_chain
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'appends validation error' do
      expect(pipeline.errors.to_a)
        .to include 'Failed to build the pipeline!'
    end

    it 'wastes pipeline iid' do
      expect(InternalId.ci_pipelines.where(project_id: project.id).last.last_value).to be > 0
    end
  end

  context 'when there is a seed blocks present' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project,
        current_user: user,
        origin_ref: 'master',
        seeds_block: seeds_block)
    end

    context 'when seeds block builds some resources' do
      let(:seeds_block) do
        ->(pipeline) { pipeline.variables.build(key: 'VAR', value: '123') }
      end

      it 'populates pipeline with resources described in the seeds block' do
        run_chain

        expect(pipeline).not_to be_persisted
        expect(pipeline.variables).not_to be_empty
        expect(pipeline.variables.first).not_to be_persisted
        expect(pipeline.variables.first.key).to eq 'VAR'
        expect(pipeline.variables.first.value).to eq '123'
      end

      it 'has pipeline iid' do
        run_chain

        expect(pipeline.iid).to be > 0
      end
    end

    context 'when seeds block tries to persist some resources' do
      let(:seeds_block) do
        ->(pipeline) { pipeline.variables.create!(key: 'VAR', value: '123') }
      end

      it 'raises error' do
        expect { run_chain }.to raise_error(
          ActiveRecord::RecordNotSaved,
          'You cannot call create unless the parent is saved'
        )
      end
    end
  end

  context 'when pipeline gets persisted during the process' do
    before do
      dependencies.each(&:perform!)
      pipeline.save!
    end

    it 'raises error' do
      expect { step.perform! }.to raise_error(described_class::PopulateError)
    end
  end

  context 'when variables policy is specified' do
    shared_examples_for 'a correct pipeline' do
      it 'populates pipeline according to used policies' do
        run_chain

        expect(pipeline.stages.size).to eq 1
        expect(pipeline.stages.first.statuses.size).to eq 1
        expect(pipeline.stages.first.statuses.first.name).to eq 'rspec'
      end
    end

    context 'when using only/except build policies' do
      let(:config) do
        { rspec: { script: 'rspec', stage: 'test', only: ['master'] },
          prod: { script: 'cap prod', stage: 'deploy', only: ['tags'] } }
      end

      it_behaves_like 'a correct pipeline'

      context 'when variables expression is specified' do
        context 'when pipeline iid is the subject' do
          let(:config) do
            { rspec: { script: 'rspec', only: { variables: ["$CI_PIPELINE_IID == '1'"] } },
              prod: { script: 'cap prod', only: { variables: ["$CI_PIPELINE_IID == '1000'"] } } }
          end

          it_behaves_like 'a correct pipeline'
        end
      end
    end
  end
end
