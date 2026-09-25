# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayBuildService, '#execute', feature_category: :continuous_integration do
  let_it_be_with_reload(:project) { create(:project) }
  let(:user) { create(:user, developer_of: project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, :manual, user: user, pipeline: pipeline) }
  let(:job_variables) { nil }
  let(:job_inputs) { {} }

  let(:service_result) do
    described_class.new(current_user: user, build: build, variables: job_variables, inputs: job_inputs).execute
  end

  subject(:execute_service) { service_result.payload[:job] }

  context 'when project does not have repository yet' do
    let_it_be_with_reload(:project) { create(:project) }

    it 'allows user to play build if protected branch rules are met' do
      create(:protected_branch, :developers_can_merge, name: build.ref, project: project)

      execute_service

      expect(build.reload).to be_pending
    end

    it 'does not allow user with developer role to play build' do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when project has repository' do
    let_it_be(:project) { create(:project, :small_repo) }

    it 'allows user with developer role to play a build' do
      execute_service

      expect(build.reload).to be_pending
    end

    it 'prevents a blocked developer from playing a build' do
      user.block!

      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when build is a playable manual action' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'enqueues the build and reassigns the build user', :aggregate_failures do
      expect(execute_service).to eq build
      expect(build.reload).to be_pending
      expect(build.reload.user).to eq user
    end

    context 'when a subsequent job is skipped' do
      let!(:job) { create(:ci_build, :skipped, pipeline: pipeline, stage_idx: build.stage_idx + 1) }

      it 'marks the subsequent job as processable' do
        expect { execute_service }.to change { job.reload.status }.from('skipped').to('created')
      end
    end

    context 'when variables are supplied' do
      let(:job_variables) do
        [{ key: 'first', value: 'first' },
          { key: 'second', value: 'second' }]
      end

      before_all do
        project.update!(ci_pipeline_variables_minimum_override_role: :developer)
      end

      it 'assigns the variables to the build' do
        execute_service

        expect(build.reload.job_variables.map(&:key)).to contain_exactly('first', 'second')
      end

      context 'and variables are invalid' do
        let(:job_variables) { [{}] }

        it 'resets the attributes of the build' do
          build.update!(job_variables_attributes: [{ key: 'old', value: 'old variable' }])

          execute_service

          expect(build.job_variables.map(&:key)).to contain_exactly('old')
        end
      end

      context 'when user defined variables are restricted' do
        before_all do
          project.update!(ci_pipeline_variables_minimum_override_role: :maintainer)
        end

        context 'when user is maintainer' do
          let_it_be(:maintainer_user) { create(:user, maintainer_of: project) }
          let(:user) { maintainer_user }

          it 'assigns the variables to the build' do
            execute_service

            expect(build.reload.job_variables.map(&:key)).to contain_exactly('first', 'second')
          end
        end

        context 'when user is developer' do
          it 'raises an error' do
            expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
          end
        end
      end
    end

    context 'when inputs are supplied', :aggregate_failures do
      let(:build) do
        create(:ci_build, :manual, pipeline: pipeline, options: {
          inputs: {
            environment: { type: 'string' },
            version: { type: 'string', default: '1.0' }
          }
        })
      end

      let(:job_inputs) { { environment: 'production' } }

      it 'assigns the inputs to the build' do
        execute_service

        expect(build.reload.inputs.map(&:name)).to contain_exactly('environment')
        expect(build.reload.inputs.find_by(name: 'environment').value).to eq('production')
      end

      it 'filters out inputs with default values' do
        job_inputs[:version] = '1.0'

        execute_service

        expect(build.reload.inputs.map(&:name)).to contain_exactly('environment')
      end

      context 'when inputs are invalid' do
        let(:job_inputs) { { unknown_input: 'value' } }

        it 'returns an error response and does not enqueue the build', :aggregate_failures do
          expect(service_result).to be_a(ServiceResponse)
          expect(service_result.error?).to be true
          expect(service_result.message).to include('Unknown input')
          expect(build.reload).to be_manual
        end
      end

      context 'when tracking play with new input values' do
        it 'tracks the internal event' do
          expect { execute_service }
            .to trigger_internal_events('play_job_with_new_input_values')
            .with(
              category: 'Ci::PlayBuildService',
              project: project,
              user: user
            )
        end

        context 'when all inputs match defaults' do
          let(:job_inputs) { { version: '1.0' } }

          it 'does not track the event' do
            expect { execute_service }
              .not_to trigger_internal_events('play_job_with_new_input_values')
          end
        end

        context 'when no inputs are provided' do
          let(:job_inputs) { {} }

          it 'does not track the event' do
            expect { execute_service }
              .not_to trigger_internal_events('play_job_with_new_input_values')
          end
        end
      end
    end
  end

  context 'when build is not a playable manual action' do
    let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project) }

    let(:build) { create(:ci_build, :success, pipeline: pipeline) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'duplicates the build and assigns users correctly', :aggregate_failures do
      duplicate = execute_service

      expect(duplicate).not_to eq build
      expect(duplicate).to be_pending
      expect(build.user).not_to eq user
      expect(duplicate.user).to eq user
    end

    context 'and is not retryable' do
      let(:build) { create(:ci_build, :deployment_rejected, pipeline: pipeline) }

      it 'does not duplicate or enqueue the build', :aggregate_failures do
        build_status = build.status

        expect { execute_service }.not_to change { Ci::Build.count }
        expect(build.reload.status).to eq(build_status)
      end
    end
  end

  context 'when build is not action' do
    let(:user) { create(:user) }
    let(:build) { create(:ci_build, :success, pipeline: pipeline) }

    it 'raises an error' do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when user does not have ability to trigger action' do
    let(:user) { create(:user) }
    let!(:branch) { create(:protected_branch, :developers_can_merge, name: build.ref, project: project) }

    it 'raises an error' do
      expect { execute_service }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'with rate limiting', :clean_gitlab_redis_rate_limiting, :freeze_time do
    let_it_be(:project) { create(:project, :small_repo) }

    let(:other_build) { create(:ci_build, :manual, pipeline: pipeline) }
    let(:throttle_message) { ::Gitlab::ApplicationRateLimiter.throttled_error_message }

    def play(build_to_play = build, **options)
      described_class.new(current_user: user, build: build_to_play, **options).execute
    end

    it 'does not throttle the first play' do
      expect(play).to be_success
    end

    it 'throttles the fourth play of the same job in a minute' do
      3.times { play }

      throttled = play

      expect(throttled).to be_error
      expect(throttled.reason).to eq(:rate_limited)
      expect(throttled.message).to eq(throttle_message)
    end

    it 'does not count the retry fallback of a replayed job as a retry' do
      allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_call_original
      expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?).with(:job_retry, anything)
      expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?).with(:job_retry_per_project, anything)

      # The second play of an already-enqueued job falls back to Ci::RetryJobService.
      2.times { expect(play).to be_success }
    end

    context 'when the per-project limit is exceeded' do
      before do
        stub_application_setting(job_play_limit_per_user_project: 1)
      end

      it 'throttles a play of a different job in the same project' do
        expect(play).to be_success

        expect(play(other_build).reason).to eq(:rate_limited)
      end
    end

    context 'when the per-project limit is disabled with 0' do
      before do
        stub_application_setting(job_play_limit_per_user_project: 0)
      end

      it 'does not apply the per-project limit but still enforces the per-job limit' do
        5.times { play(create(:ci_build, :manual, pipeline: pipeline)) }
        expect(play(other_build).reason).not_to eq(:rate_limited)

        3.times { play }
        expect(play.reason).to eq(:rate_limited)
      end
    end

    context 'when the per-job limit is hit repeatedly' do
      before do
        # Small enough that blocked calls would exhaust it if they counted.
        stub_application_setting(job_play_limit_per_user_project: 4)
      end

      it 'does not spend the per-project budget on already-blocked per-job calls' do
        8.times { play }
        expect(play.reason).to eq(:rate_limited)

        expect(play(other_build).reason).not_to eq(:rate_limited)
      end
    end

    context 'with a different user' do
      let(:other_user) { create(:user, developer_of: project) }

      before do
        stub_application_setting(job_play_limit_per_user_project: 1)
      end

      it 'keeps separate buckets per user' do
        expect(play).to be_success
        expect(play.reason).to eq(:rate_limited)

        expect(described_class.new(current_user: other_user, build: other_build).execute).to be_success
      end
    end

    context 'when the user cannot play the job' do
      let(:user) { create(:user) }

      before do
        stub_application_setting(job_play_limit_per_user_project: 1)
      end

      it 'counts the rejected call against the bucket' do
        expect { play }.to raise_error(Gitlab::Access::AccessDeniedError)

        expect(play.reason).to eq(:rate_limited)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(rate_limit_job_play: false)
        stub_application_setting(job_play_limit_per_user_project: 1)
      end

      it 'does not throttle' do
        2.times { expect(play.reason).not_to eq(:rate_limited) }
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

        3.times { play(rate_limit: false) }
      end
    end

    it 'logs the throttled call' do
      allow(Gitlab::AppJsonLogger).to receive(:info)
      stub_application_setting(job_play_limit_per_user_project: 1)

      2.times { play }

      expect(Gitlab::AppJsonLogger).to have_received(:info).with(
        a_hash_including(
          Labkit::Fields::CLASS_NAME => described_class.to_s,
          message: 'Job play rate limit exceeded',
          Labkit::Fields::GL_PROJECT_ID => project.id,
          job_id: build.id,
          Labkit::Fields::GL_USER_ID => user.id
        )
      ).once
    end
  end
end
