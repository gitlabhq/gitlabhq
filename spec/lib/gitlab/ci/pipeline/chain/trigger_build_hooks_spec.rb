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

  it 'enqueues ExecutePipelineBuildHooksWorker with pipeline_id' do
    expect(::Ci::ExecutePipelineBuildHooksWorker).to receive(:perform_async).with(pipeline.id)

    run_chain
  end
end
