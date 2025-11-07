# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Job confirmation integration', :freeze_time, :clean_gitlab_redis_cache, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }
  let_it_be(:runner, freeze: true) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:runner_manager, freeze: true) { create(:ci_runner_machine, runner: runner, system_xid: 'abc') }

  let!(:build) { create(:ci_build, :pending, :queued, pipeline: pipeline, created_at: 10.seconds.ago) }

  describe 'Full job confirmation workflow' do
    shared_examples 'the legacy workflow (direct transition to running)' do
      it 'follows the legacy workflow (direct transition to running)' do
        travel 2.seconds

        # Step 1: Runner requests a job
        post '/api/v4/jobs/request', params: runner_params

        expect(response).to have_gitlab_http_status(:created)
        job_response = Gitlab::Json.parse(response.body)
        job_id = job_response['id']
        job_token = job_response['token']

        # Verify job transitioned directly to running (feature flag disabled)
        job = Ci::Build.find(job_id)
        expect(job).to be_running
        expect(job.runner_ack_wait_status).to eq(:not_waiting)
        expect(job.runner_id).to eq(runner.id)
        expect(job.runner_manager).to eq(runner_manager)
        expect(job.started_at).to be_present
        expect(job.started_at - job.queued_at).to eq 2.seconds

        # Verify job is removed from pending builds queue
        expect(Ci::PendingBuild.where(build: job)).to be_empty

        # Verify running build tracking entry was created
        running_build = Ci::RunningBuild.find_by(build: job)
        expect(running_build).to be_present

        # Step 2: Runner can update job status normally
        travel 10.seconds

        put "/api/v4/jobs/#{job_id}", params: {
          token: job_token,
          state: 'success'
        }

        expect(response).to have_gitlab_http_status(:ok)

        job.reload
        expect(job).to be_success
        expect(job.started_at - job.queued_at).to eq 2.seconds
        expect(job.finished_at).to be_present
        expect(job.duration).to eq 10.seconds
      end

      it 'rejects two-phase commit workflow attempts' do
        # Step 1: Runner requests a job
        post '/api/v4/jobs/request', params: runner_params

        expect(response).to have_gitlab_http_status(:created)
        job_response = Gitlab::Json.parse(response.body)
        job_id = job_response['id']
        job_token = job_response['token']

        # Job should be running already (feature flag disabled)
        job = Ci::Build.find(job_id)
        expect(job).to be_running

        # Step 2: Attempt to send keep-alive signals (should be rejected)
        put "/api/v4/jobs/#{job_id}", params: {
          token: job_token,
          state: 'pending'
        }

        # Should return 400 because job is already running
        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with runner supporting two_phase_job_commit' do
      let(:runner_params) do
        {
          token: runner.token,
          system_id: runner_manager.system_xid,
          info: {
            features: {
              two_phase_job_commit: true
            }
          }
        }
      end

      it 'follows the complete job confirmation workflow' do
        # Step 1: Runner requests a job
        post '/api/v4/jobs/request', params: runner_params

        expect(response).to have_gitlab_http_status(:created)
        job_response = Gitlab::Json.parse(response.body)
        job_id = job_response['id']
        job_token = job_response['token']

        # Verify job is assigned to runner but still pending
        job = Ci::Build.find(job_id)
        expect(job).to be_pending
        expect(job.runner_ack_wait_status).to eq(:waiting)
        expect(job.runner_id).to eq(runner.id)
        expect(job.runner_manager).to be_nil
        expect(job.runner_manager_id_waiting_for_ack).to eq(runner_manager.id)
        expect(job.queued_at - job.created_at).to eq 10.seconds

        # Verify job is removed from pending builds queue
        expect(Ci::PendingBuild.where(build: job)).to be_empty

        # Step 2: Runner sends keep-alive signals using PUT /jobs/:id with state=pending
        3.times do
          travel 2.seconds

          put "/api/v4/jobs/#{job_id}", params: {
            token: job_token,
            state: 'pending'
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq('200')

          # Job should still be pending
          job.reload
          expect(job).to be_pending
          expect(job.runner_manager_id_waiting_for_ack).to eq(runner_manager.id)
        end

        # Step 3: Runner accepts the job using PUT /jobs/:id with state=running
        put "/api/v4/jobs/#{job_id}", params: {
          token: job_token,
          state: 'running'
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq('200')

        # Verify job transitioned to running
        job.reload
        expect(job).to be_running
        expect(job.runner_ack_wait_status).to eq(:not_waiting)
        expect(job.started_at).to be_present
        expect(job.started_at - job.queued_at).to eq 6.seconds
        expect(job.runner_manager_id_waiting_for_ack).to be_nil

        # Verify running build tracking entry was created
        running_build = Ci::RunningBuild.find_by(build: job)
        expect(running_build).to be_present
        expect(running_build.runner_id).to eq(runner.id)

        # Step 4: Runner can now update job status normally using PUT /jobs/:id
        travel 5.minutes

        put "/api/v4/jobs/#{job_id}", params: {
          token: job_token,
          state: 'success'
        }

        expect(response).to have_gitlab_http_status(:ok)

        job.reload
        expect(job).to be_success
        expect(job.finished_at).to be_present
        expect(job.duration).to eq 5.minutes
      end

      it 'prevents other runners from picking up assigned job' do
        # Step 1: First runner requests a job
        post '/api/v4/jobs/request', params: runner_params

        expect(response).to have_gitlab_http_status(:created)
        job_response = Gitlab::Json.parse(response.body)
        job_id = job_response['id']

        # Verify job is assigned and removed from queue
        job = Ci::Build.find(job_id)
        expect(job).to be_pending
        expect(job.runner_id).to eq(runner.id)
        expect(Ci::PendingBuild.where(build: job)).to be_empty

        # Step 2: Second runner tries to request a job
        other_runner = create(:ci_runner, :project, projects: [project])
        post '/api/v4/jobs/request', params: {
          token: other_runner.token,
          info: { features: { two_phase_job_commit: true } }
        }

        # Should not get the already assigned job
        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'when allow_runner_job_acknowledgement feature flag is disabled' do
        before do
          stub_feature_flags(allow_runner_job_acknowledgement: false)
        end

        it_behaves_like 'the legacy workflow (direct transition to running)'
      end
    end

    context 'with feature flag toggle during two-phase commit' do
      context 'when feature flag is disabled after job pickup' do
        it 'completes acknowledgment flow despite FF being disabled' do
          # Step 1: Runner picks up job with two-phase commit
          post api('/jobs/request'), params: {
            token: runner.token,
            info: { features: { two_phase_job_commit: true } }
          }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['id']).to eq(build.id)

          # Verify job is in waiting state
          build.reload
          expect(build).to be_pending
          expect(build.runner_ack_wait_status).to eq(:waiting)

          # Step 2: Disable feature flag mid-flight
          stub_feature_flags(allow_runner_job_acknowledgement: false)

          # Step 3: Runner sends acknowledgment
          put api("/jobs/#{build.id}"), params: {
            token: build.token,
            state: 'running'
          }

          # Should still process the acknowledgment
          expect(response).to have_gitlab_http_status(:ok)
          expect(build.reload).to be_running

          # Verify Redis state is cleaned up
          ::Gitlab::Redis::SharedState.with do |redis|
            expect(redis.exists(runner_build_ack_queue_key)).to be_zero
          end
        end

        context 'with multiple runners' do
          let(:runner2) { create(:ci_runner, :project, projects: [project]) }

          it 'prevents race conditions when FF toggled' do
            # Runner 1 picks up job with FF enabled
            post api('/jobs/request'), params: {
              token: runner.token,
              info: { features: { two_phase_job_commit: true } }
            }
            expect(response).to have_gitlab_http_status(:created)

            # Disable FF
            stub_feature_flags(allow_runner_job_acknowledgement: false)

            # Runner 2 should not see the job
            post api('/jobs/request'), params: {
              token: runner2.token
            }
            expect(response).to have_gitlab_http_status(:no_content)

            # Runner 1 acknowledges
            put api("/jobs/#{build.id}"), params: {
              token: build.token,
              state: 'running'
            }
            expect(response).to have_gitlab_http_status(:ok)

            # Job should be running with runner 1
            expect(build.reload.runner).to eq(runner)
          end
        end
      end

      context 'when feature flag is re-enabled during acknowledgment' do
        it 'maintains consistent behavior' do
          # Start with FF disabled
          stub_feature_flags(allow_runner_job_acknowledgement: false)

          # Pick up job normally (no two-phase commit)
          post api('/jobs/request'), params: {
            token: runner.token
          }
          expect(response).to have_gitlab_http_status(:created)
          expect(build.reload).to be_running

          # Enable FF
          stub_feature_flags(allow_runner_job_acknowledgement: true)

          # Status update should work normally
          put api("/jobs/#{build.id}"), params: {
            token: build.token,
            state: 'running',
            checksum: 'abc123'
          }
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      private

      def runner_build_ack_queue_key
        build.send(:runner_ack_queue).redis_key
      end
    end

    context 'with legacy runner (no two_phase_job_commit support)' do
      let(:runner_params) do
        {
          token: runner.token,
          system_id: runner_manager.system_xid,
          info: {
            features: {
              other_feature: true
            }
          }
        }
      end

      it_behaves_like 'the legacy workflow (direct transition to running)'
    end
  end
end
