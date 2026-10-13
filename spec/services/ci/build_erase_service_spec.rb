# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildEraseService, feature_category: :continuous_integration do
  let_it_be(:user) { user }

  let(:build) { create(:ci_build, :artifacts, :trace_artifact, artifacts_expire_at: 100.days.from_now) }

  subject(:service) { described_class.new(build, user) }

  describe '#execute' do
    context 'when build is erasable' do
      before do
        allow(build).to receive(:erasable?).and_return(true)
      end

      it 'is successful' do
        result = service.execute

        expect(result).to be_success
      end

      it 'erases artifacts' do
        service.execute

        expect(build.artifacts_file).not_to be_present
        expect(build.artifacts_metadata).not_to be_present
      end

      it 'erases trace' do
        service.execute

        expect(build.trace).not_to exist
      end

      it 'records erasure detail' do
        freeze_time do
          service.execute

          expect(build.erased_by).to eq(user)
          expect(build.erased_at).to eq(Time.current)
          expect(build.artifacts_expire_at).to be_nil
        end
      end

      context 'when project is undergoing statistics refresh' do
        before do
          allow(build.project).to receive(:refreshing_build_artifacts_size?).and_return(true)
        end

        it 'logs a warning' do
          expect(Gitlab::ProjectStatsRefreshConflictsLogger)
            .to receive(:warn_artifact_deletion_during_stats_refresh)
            .with(method: 'Ci::BuildEraseService#execute', project_id: build.project_id)

          service.execute
        end
      end
    end

    context 'when build is not erasable' do
      before do
        allow(build).to receive(:erasable?).and_return(false)
      end

      it 'is not successful' do
        result = service.execute

        expect(result).to be_error
        expect(result.http_status).to eq(:unprocessable_entity)
      end

      it 'does not erase artifacts' do
        service.execute

        expect(build.artifacts_file).to be_present
        expect(build.artifacts_metadata).to be_present
      end

      it 'does not erase trace' do
        service.execute

        expect(build.trace).to exist
      end
    end

    context 'with rate limiting', :clean_gitlab_redis_rate_limiting, :freeze_time do
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project) }
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

      let(:build) { create(:ci_build, :erasable, pipeline: pipeline) }
      let(:other_build) { create(:ci_build, :erasable, pipeline: pipeline) }
      let(:throttle_message) { ::Gitlab::ApplicationRateLimiter.throttled_error_message }

      def erase(build_to_erase = build)
        described_class.new(build_to_erase, user).execute
      end

      it 'does not throttle the first erase' do
        expect(erase).to be_success
      end

      it 'throttles the sixth erase of the same job in a minute, counting rejected calls', :aggregate_failures do
        5.times { erase }

        throttled = erase

        expect(throttled).to be_error
        expect(throttled.reason).to eq(:rate_limited)
        expect(throttled.message).to eq(throttle_message)
        expect(throttled.payload).to include(job: build, reason: :rate_limited)
      end

      context 'when the per-project limit is exceeded' do
        before do
          stub_application_setting(job_erase_limit_per_user_project: 1)
        end

        it 'throttles an erase of a different job in the same project' do
          expect(erase).to be_success

          expect(erase(other_build).reason).to eq(:rate_limited)
        end
      end

      context 'when the per-project limit is disabled with 0' do
        before do
          stub_application_setting(job_erase_limit_per_user_project: 0)
        end

        it 'does not apply the per-project limit but still enforces the per-job limit' do
          5.times { erase(create(:ci_build, :erasable, pipeline: pipeline)) }
          expect(erase(other_build).reason).not_to eq(:rate_limited)

          5.times { erase }
          expect(erase.reason).to eq(:rate_limited)
        end
      end

      context 'with a different user' do
        let_it_be(:other_user) { create(:user) }

        before do
          stub_application_setting(job_erase_limit_per_user_project: 1)
        end

        it 'keeps separate buckets per user' do
          expect(erase).to be_success
          expect(erase(other_build).reason).to eq(:rate_limited)

          expect(described_class.new(other_build, other_user).execute).to be_success
        end
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(rate_limit_job_erase: false)
          stub_application_setting(job_erase_limit_per_user_project: 1)
        end

        it 'does not throttle', :aggregate_failures do
          expect(erase).to be_success
          expect(erase(other_build)).to be_success
        end
      end

      it 'logs the throttled call' do
        allow(Gitlab::AppJsonLogger).to receive(:info)
        stub_application_setting(job_erase_limit_per_user_project: 1)

        erase
        erase(other_build)

        expect(Gitlab::AppJsonLogger).to have_received(:info).with(
          a_hash_including(
            Labkit::Fields::CLASS_NAME => described_class.to_s,
            message: 'Job erase rate limit exceeded',
            rate_limit: 'job_erase_per_project',
            Labkit::Fields::GL_PROJECT_ID => project.id,
            job_id: other_build.id,
            Labkit::Fields::GL_USER_ID => user.id
          )
        ).once
      end

      it 'logs the per-job limit when it fires' do
        allow(Gitlab::AppJsonLogger).to receive(:info)

        6.times { erase }

        expect(Gitlab::AppJsonLogger).to have_received(:info).with(
          a_hash_including(message: 'Job erase rate limit exceeded', rate_limit: 'job_erase')
        ).once
      end

      context 'when the caller opts out with rate_limit: false' do
        before do
          stub_application_setting(job_erase_limit_per_user_project: 1)
        end

        it 'never consults the rate limiter' do
          allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_call_original
          expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?).with(:job_erase, anything)
          expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?).with(:job_erase_per_project, anything)

          described_class.new(build, user, rate_limit: false).execute
          described_class.new(other_build, user, rate_limit: false).execute
        end
      end
    end
  end
end
