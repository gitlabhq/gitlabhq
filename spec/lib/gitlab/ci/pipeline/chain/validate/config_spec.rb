require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Validate::Config do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      save_incompleted: true)
  end

  let!(:step) { described_class.new(pipeline, command) }

  before do
    step.perform!
  end

  context 'when pipeline has no YAML configuration' do
    let(:pipeline) do
      build_stubbed(:ci_pipeline, project: project)
    end

    it 'appends errors about missing configuration' do
      expect(pipeline.errors.to_a)
        .to include 'Missing .gitlab-ci.yml file'
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end
  end

  context 'when YAML configuration contains errors' do
    let(:pipeline) do
      build(:ci_pipeline, project: project, config: 'invalid YAML')
    end

    it 'appends errors about YAML errors' do
      expect(pipeline.errors.to_a)
        .to include 'Invalid configuration format'
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    context 'when saving incomplete pipeline is allowed' do
      let(:command) do
        double('command', project: project,
                          current_user: user,
                          save_incompleted: true)
      end

      it 'fails the pipeline' do
        expect(pipeline.reload).to be_failed
      end

      it 'sets a config error failure reason' do
        expect(pipeline.reload.config_error?).to eq true
      end
    end

    context 'when saving incomplete pipeline is not allowed' do
      let(:command) do
        double('command', project: project,
                          current_user: user,
                          save_incompleted: false)
      end

      it 'does not drop pipeline' do
        expect(pipeline).not_to be_failed
        expect(pipeline).not_to be_persisted
      end
    end
  end

  context 'when pipeline contains configuration validation errors' do
    let(:config) { { rspec: {} } }

    let(:pipeline) do
      build(:ci_pipeline, project: project, config: config)
    end

    it 'appends configuration validation errors to pipeline errors' do
      expect(pipeline.errors.to_a)
        .to include "jobs:rspec config can't be blank"
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end
  end

  context 'when pipeline is correct and complete' do
    let(:pipeline) do
      build(:ci_pipeline_with_one_job, project: project)
    end

    it 'does not invalidate the pipeline' do
      expect(pipeline).to be_valid
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end
  end
end
