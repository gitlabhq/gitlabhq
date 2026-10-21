# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildCancelService, feature_category: :continuous_integration do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'develop') }

  describe '#execute' do
    subject(:execute) { described_class.new(build, user).execute }

    context 'when user is authorized to cancel the build' do
      before_all do
        project.add_developer(user)
      end

      context 'when build is cancelable' do
        let!(:build) { create(:ci_build, :cancelable, pipeline: pipeline) }

        it 'transits build to canceled', :aggregate_failures do
          response = execute

          expect(response).to be_success
          expect(response.payload.reload).to be_canceled
        end
      end

      context 'when build is not cancelable' do
        let!(:build) { create(:ci_build, :canceled, pipeline: pipeline) }

        it 'responds with unprocessable entity', :aggregate_failures do
          response = execute

          expect(response).to be_error
          expect(response.http_status).to eq(:unprocessable_entity)
        end
      end

      context 'when build is force cancelable' do
        let!(:build) { create(:ci_build, :canceling, pipeline: pipeline) }

        it 'responds to default request with unprocessable entity', :aggregate_failures do
          response = execute

          expect(response).to be_error
          expect(response.http_status).to eq(:unprocessable_entity)
        end

        context 'for a force_cancel request' do
          let(:force_execute) { described_class.new(build, user, true).execute }

          context 'as a developer on the project' do
            it 'responds with unprocessable entity', :aggregate_failures do
              response = force_execute

              expect(response).to be_error
              expect(response.http_status).to eq(:unprocessable_entity)
            end
          end

          context 'as a maintainer on the project' do
            before_all do
              project.add_maintainer(user)
            end

            it 'transits build to canceled', :aggregate_failures do
              response = force_execute

              expect(response).to be_success
              expect(response.payload.reload).to be_canceled
            end
          end
        end
      end
    end

    context 'when user is not authorized to cancel the build' do
      let!(:build) { create(:ci_build, :cancelable, pipeline: pipeline) }

      it 'responds with forbidden', :aggregate_failures do
        response = execute

        expect(response).to be_error
        expect(response.http_status).to eq(:forbidden)
      end
    end

    context 'with rate limiting', :clean_gitlab_redis_rate_limiting, :freeze_time do
      let(:build) { create(:ci_build, :running, pipeline: pipeline) }
      let(:other_build) { create(:ci_build, :running, pipeline: pipeline) }
      let(:throttle_message) { ::Gitlab::ApplicationRateLimiter.throttled_error_message }

      before_all do
        project.add_developer(user)
      end

      def cancel(build_to_cancel = build)
        described_class.new(build_to_cancel, user).execute
      end

      it 'does not throttle the first cancel' do
        expect(cancel).to be_success
      end

      it 'throttles the sixth cancel of the same job in a minute, counting rejected calls', :aggregate_failures do
        5.times { cancel }

        throttled = cancel

        expect(throttled).to be_error
        expect(throttled.reason).to eq(:rate_limited)
        expect(throttled.message).to eq(throttle_message)
        expect(throttled.payload).to include(job: build, reason: :rate_limited)
      end

      context 'when the per-project limit is exceeded' do
        before do
          stub_application_setting(job_cancel_limit_per_user_project: 1)
        end

        it 'throttles a cancel of a different job in the same project' do
          expect(cancel).to be_success

          expect(cancel(other_build).reason).to eq(:rate_limited)
        end
      end

      context 'when the per-project limit is disabled with 0' do
        before do
          stub_application_setting(job_cancel_limit_per_user_project: 0)
        end

        it 'does not apply the per-project limit but still enforces the per-job limit' do
          5.times { cancel(create(:ci_build, :running, pipeline: pipeline)) }
          expect(cancel(other_build).reason).not_to eq(:rate_limited)

          5.times { cancel }
          expect(cancel.reason).to eq(:rate_limited)
        end
      end

      context 'with a different user' do
        let_it_be(:other_user) { create(:user, developer_of: project) }

        before do
          stub_application_setting(job_cancel_limit_per_user_project: 1)
        end

        it 'keeps separate buckets per user' do
          expect(cancel).to be_success
          expect(cancel(other_build).reason).to eq(:rate_limited)

          expect(described_class.new(other_build, other_user).execute).to be_success
        end
      end

      context 'when the user cannot cancel the job' do
        let(:user) { create(:user) }

        before do
          stub_application_setting(job_cancel_limit_per_user_project: 1)
        end

        it 'counts the rejected call against the bucket', :aggregate_failures do
          expect(cancel.http_status).to eq(:forbidden)

          expect(cancel(other_build).reason).to eq(:rate_limited)
        end
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(rate_limit_job_cancel: false)
          stub_application_setting(job_cancel_limit_per_user_project: 1)
        end

        it 'does not throttle', :aggregate_failures do
          expect(cancel).to be_success
          expect(cancel(other_build)).to be_success
        end
      end

      it 'logs the throttled call' do
        allow(Gitlab::AppJsonLogger).to receive(:info)
        stub_application_setting(job_cancel_limit_per_user_project: 1)

        cancel
        cancel(other_build)

        expect(Gitlab::AppJsonLogger).to have_received(:info).with(
          a_hash_including(
            Labkit::Fields::CLASS_NAME => described_class.to_s,
            message: 'Job cancel rate limit exceeded',
            rate_limit: 'job_cancel_per_project',
            Labkit::Fields::GL_PROJECT_ID => project.id,
            job_id: other_build.id,
            Labkit::Fields::GL_USER_ID => user.id
          )
        ).once
      end

      it 'logs the per-job limit when it fires' do
        allow(Gitlab::AppJsonLogger).to receive(:info)

        6.times { cancel }

        expect(Gitlab::AppJsonLogger).to have_received(:info).with(
          a_hash_including(message: 'Job cancel rate limit exceeded', rate_limit: 'job_cancel')
        ).once
      end
    end
  end
end
