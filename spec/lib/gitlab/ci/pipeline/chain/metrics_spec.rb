# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Metrics, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project, ref: 'master', user: user, name: 'Build pipeline')
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

  it 'increments the metrics' do
    expect(::Gitlab::Ci::Pipeline::Metrics.pipelines_created_counter)
      .to receive(:increment)
      .with({ partition_id: instance_of(Integer), source: 'push' })

    run_chain
  end

  context 'with pipeline name' do
    it 'creates snowplow event' do
      run_chain

      expect_snowplow_event(
        category: described_class.to_s,
        action: 'create_pipeline_with_name',
        project: pipeline.project,
        user: pipeline.user,
        namespace: pipeline.project.namespace
      )
    end
  end

  context 'without pipeline name' do
    let_it_be(:pipeline) do
      create(:ci_pipeline, project: project, ref: 'master', user: user)
    end

    it 'does not create snowplow event' do
      run_chain

      expect_no_snowplow_event
    end
  end
end
