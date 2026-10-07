# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::TriggerBuildHooks, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project, ref: 'master', user: user)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      origin_ref: 'master')
  end

  let(:step) { described_class.new(pipeline, command) }

  subject(:run_chain) { step.perform! }

  it 'does not break the chain' do
    run_chain

    expect(step.break?).to be false
  end

  context 'when the project has job hooks' do
    before do
      allow(project).to receive(:has_active_hooks?).with(:job_hooks).and_return(true)
    end

    it 'enqueues ExecutePipelineBuildHooksWorker with pipeline_id' do
      expect(::Ci::ExecutePipelineBuildHooksWorker).to receive(:perform_async).with(pipeline.id)

      run_chain
    end
  end

  context 'when the project has job integrations' do
    before do
      allow(project).to receive(:has_active_hooks?).with(:job_hooks).and_return(false)
      allow(project).to receive(:has_active_integrations?).with(:job_hooks).and_return(true)
    end

    it 'enqueues ExecutePipelineBuildHooksWorker with pipeline_id' do
      expect(::Ci::ExecutePipelineBuildHooksWorker).to receive(:perform_async).with(pipeline.id)

      run_chain
    end
  end

  context 'when the project has no job hooks or integrations' do
    it 'does not enqueue ExecutePipelineBuildHooksWorker' do
      expect(::Ci::ExecutePipelineBuildHooksWorker).not_to receive(:perform_async)

      run_chain
    end
  end
end
