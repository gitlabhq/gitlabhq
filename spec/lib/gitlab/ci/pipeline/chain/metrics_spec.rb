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

  context 'with inputs' do
    let(:inputs) do
      {
        deploy_strategy: 'manual',
        job_stage: 'deploy',
        test_script: 'echo "test"'
      }
    end

    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project,
        current_user: user,
        origin_ref: 'master',
        inputs: inputs
      )
    end

    it 'tracks the usage of inputs' do
      expect { run_chain }.to trigger_internal_events('create_pipeline_with_inputs').with(
        project: pipeline.project,
        user: pipeline.user,
        additional_properties: {
          label: 'push',
          property: 'unknown_source',
          value: 3
        }
      )
    end
  end

  describe 'build creation tracking' do
    let_it_be(:stage) { create(:ci_stage, pipeline: pipeline, project: project) }

    context 'when pipeline has builds' do
      let_it_be(:build1) do
        create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, name: 'rspec', user: user)
      end

      let_it_be(:build2) do
        create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project, name: 'rubocop', user: user)
      end

      before do
        pipeline.builds.reload
      end

      it 'tracks build creation events' do
        expect { run_chain }
          .to trigger_internal_events('create_ci_build').twice
      end
    end

    context 'when pipeline has builds with id_tokens' do
      let_it_be(:build_with_tokens) do
        create(:ci_build, pipeline: pipeline, ci_stage: stage, project: project,
          user: user, id_tokens: { 'ID_TOKEN_1' => { aud: 'developers' } })
      end

      before do
        pipeline.builds.reload
      end

      it 'tracks id_tokens usage' do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter)
          .to receive(:track_event)
          .with('i_ci_secrets_management_id_tokens_build_created', values: [user.id])

        run_chain
      end

      it 'tracks Snowplow event for id_tokens' do
        run_chain

        expect_snowplow_event(
          category: 'Ci::Build',
          action: 'create_id_tokens',
          namespace: build_with_tokens.namespace,
          user: user,
          label: 'redis_hll_counters.ci_secrets_management.i_ci_secrets_management_id_tokens_build_created_monthly',
          ultimate_namespace_id: build_with_tokens.namespace.root_ancestor.id,
          context: [Gitlab::Tracking::ServicePingContext.new(
            data_source: :redis_hll,
            event: 'i_ci_secrets_management_id_tokens_build_created'
          ).to_context.to_json]
        )
      end
    end

    context 'when pipeline has no builds' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project, ref: 'master', user: user) }

      it 'does not track any build events' do
        expect(Gitlab::InternalEvents).not_to receive(:track_event).with('create_ci_build', anything)

        run_chain
      end
    end
  end
end
