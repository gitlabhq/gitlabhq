require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Create do
  set(:project) { create(:project) }
  set(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_pipeline_with_one_job, project: project,
                                     ref: 'master')
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user, seeds_block: nil)
  end

  let(:step) { described_class.new(pipeline, command) }

  before do
    step.perform!
  end

  context 'when pipeline is ready to be saved' do
    it 'saves a pipeline' do
      expect(pipeline).to be_persisted
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'creates stages' do
      expect(pipeline.reload.stages).to be_one
    end
  end

  context 'when pipeline has validation errors' do
    let(:pipeline) do
      build(:ci_pipeline, project: project, ref: nil)
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'appends validation error' do
      expect(pipeline.errors.to_a)
        .to include /Failed to persist the pipeline/
    end
  end

  context 'when there is a seed block present' do
    let(:seeds) { spy('pipeline seeds') }

    let(:command) do
      double('command', project: project,
                        current_user: user,
                        seeds_block: seeds)
    end

    it 'executes the block' do
      expect(seeds).to have_received(:call).with(pipeline)
    end
  end
end
