# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayBridgeService, '#execute', feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:downstream_project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: [project, downstream_project]) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project) }
  let(:instance) { described_class.new(project, user) }

  subject(:execute_service) { instance.execute(bridge) }

  context 'when user can run the bridge' do
    it 'marks the bridge pending' do
      execute_service

      expect(bridge.reload).to be_pending
    end

    it "updates bridge's user" do
      execute_service

      expect(bridge.reload.user).to eq(user)
    end

    it 'enqueues Ci::CreateDownstreamPipelineWorker' do
      expect(::Ci::CreateDownstreamPipelineWorker).to receive(:perform_async).with(bridge.id)

      execute_service
    end

    context 'when a subsequent job is skipped' do
      let!(:job) { create(:ci_build, :skipped, pipeline: pipeline, stage_idx: bridge.stage_idx + 1) }

      before do
        create(:ci_build_need, build: job, name: bridge.name)
      end

      it 'marks the subsequent job as processable' do
        expect { execute_service }.to change { job.reload.status }.from('skipped').to('created')
      end
    end

    context 'when bridge is not playable' do
      let(:bridge) { create(:ci_bridge, :failed, pipeline: pipeline, downstream: downstream_project) }

      it 'raises StateMachines::InvalidTransition' do
        expect { execute_service }.to raise_error StateMachines::InvalidTransition
      end
    end
  end

  context 'when user can not run the bridge' do
    let_it_be(:user) { create(:user, developer_of: project) }

    it 'raises an error' do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'with rate limiting', :clean_gitlab_redis_rate_limiting, :freeze_time do
    let(:other_bridge) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project) }

    def play(bridge_to_play = bridge, **options)
      described_class.new(project, user, **options).execute(bridge_to_play)
    end

    it 'does not throttle the first play' do
      expect(play).to be_success
    end

    it 'throttles the fourth play of the same bridge in a minute, counting rejected calls' do
      play
      2.times { expect { play }.to raise_error(StateMachines::InvalidTransition) }

      expect(play.reason).to eq(:rate_limited)
    end

    it 'logs the throttled call' do
      allow(Gitlab::AppJsonLogger).to receive(:info)
      stub_application_setting(job_play_limit_per_user_project: 1)

      play
      play(other_bridge)

      expect(Gitlab::AppJsonLogger).to have_received(:info).with(
        a_hash_including(
          Labkit::Fields::CLASS_NAME => described_class.to_s,
          message: 'Job play rate limit exceeded',
          Labkit::Fields::GL_PROJECT_ID => project.id,
          job_id: other_bridge.id,
          Labkit::Fields::GL_USER_ID => user.id
        )
      ).once
    end

    it 'shares the job play buckets with builds' do
      stub_application_setting(job_play_limit_per_user_project: 1)

      expect(play).to be_success

      build = create(:ci_build, :manual, pipeline: pipeline)
      throttled = Ci::PlayBuildService.new(current_user: user, build: build).execute

      expect(throttled.reason).to eq(:rate_limited)
    end

    context 'when the per-project limit is exceeded' do
      before do
        stub_application_setting(job_play_limit_per_user_project: 1)
      end

      it 'throttles a play of a different bridge in the same project', :aggregate_failures do
        expect(play).to be_success

        throttled = play(other_bridge)

        expect(throttled).to be_error
        expect(throttled.reason).to eq(:rate_limited)
        expect(throttled.message).to eq(::Gitlab::ApplicationRateLimiter.throttled_error_message)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(rate_limit_job_play: false)
        stub_application_setting(job_play_limit_per_user_project: 1)
      end

      it 'does not throttle' do
        expect(play).to be_success
        expect(play(other_bridge)).to be_success
      end
    end

    context 'when the caller opts out with rate_limit: false' do
      before do
        stub_application_setting(job_play_limit_per_user_project: 1)
      end

      it 'never consults the rate limiter' do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_call_original
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?).with(:job_play, anything)
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?).with(:job_play_per_project, anything)

        play(rate_limit: false)
        play(other_bridge, rate_limit: false)
      end
    end
  end
end
