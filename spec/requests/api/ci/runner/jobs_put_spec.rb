# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state do
  include StubGitlabCalls
  include RedisHelpers
  include WorkhorseHelpers

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
    allow_any_instance_of(::Ci::Runner).to receive(:cache_attributes)
  end

  describe '/api/v4/jobs' do
    let(:root_namespace) { create(:namespace) }
    let(:namespace) { create(:namespace, parent: root_namespace) }
    let(:project) { create(:project, namespace: namespace, shared_runners_enabled: false) }
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
    let(:runner) { create(:ci_runner, :project, projects: [project]) }
    let(:user) { create(:user) }
    let(:job) do
      create(:ci_build, :artifacts, :extended_options,
             pipeline: pipeline, name: 'spinach', stage: 'test', stage_idx: 0)
    end

    describe 'PUT /api/v4/jobs/:id' do
      let(:job) do
        create(:ci_build, :pending, :trace_live, pipeline: pipeline, project: project, user: user, runner_id: runner.id)
      end

      before do
        job.run!
      end

      it_behaves_like 'API::CI::Runner application context metadata', '/api/:version/jobs/:id' do
        let(:send_request) { update_job(state: 'success') }
      end

      it 'updates runner info' do
        expect { update_job(state: 'success') }.to change { runner.reload.contacted_at }
      end

      context 'when status is given' do
        it 'mark job as succeeded' do
          update_job(state: 'success')

          job.reload
          expect(job).to be_success
        end

        it 'mark job as failed' do
          update_job(state: 'failed')

          job.reload
          expect(job).to be_failed
          expect(job).to be_unknown_failure
        end

        context 'when failure_reason is script_failure' do
          before do
            update_job(state: 'failed', failure_reason: 'script_failure')
            job.reload
          end

          it { expect(job).to be_script_failure }
        end

        context 'when failure_reason is runner_system_failure' do
          before do
            update_job(state: 'failed', failure_reason: 'runner_system_failure')
            job.reload
          end

          it { expect(job).to be_runner_system_failure }
        end

        context 'when failure_reason is unrecognized value' do
          before do
            update_job(state: 'failed', failure_reason: 'what_is_this')
            job.reload
          end

          it { expect(job).to be_unknown_failure }
        end

        context 'when failure_reason is job_execution_timeout' do
          before do
            update_job(state: 'failed', failure_reason: 'job_execution_timeout')
            job.reload
          end

          it { expect(job).to be_job_execution_timeout }
        end

        context 'when failure_reason is unmet_prerequisites' do
          before do
            update_job(state: 'failed', failure_reason: 'unmet_prerequisites')
            job.reload
          end

          it { expect(job).to be_unmet_prerequisites }
        end
      end

      context 'when trace is given' do
        it 'creates a trace artifact' do
          allow(BuildFinishedWorker).to receive(:perform_async).with(job.id) do
            ArchiveTraceWorker.new.perform(job.id)
          end

          update_job(state: 'success', trace: 'BUILD TRACE UPDATED')

          job.reload
          expect(response).to have_gitlab_http_status(:ok)
          expect(job.trace.raw).to eq 'BUILD TRACE UPDATED'
          expect(job.job_artifacts_trace.open.read).to eq 'BUILD TRACE UPDATED'
        end

        context 'when concurrent update of trace is happening' do
          before do
            job.trace.write('wb') do
              update_job(state: 'success', trace: 'BUILD TRACE UPDATED')
            end
          end

          it 'returns that operation conflicts' do
            expect(response).to have_gitlab_http_status(:conflict)
          end
        end
      end

      context 'when no trace is given' do
        it 'does not override trace information' do
          update_job

          expect(job.reload.trace.raw).to eq 'BUILD TRACE'
        end

        context 'when running state is sent' do
          it 'updates update_at value' do
            expect { update_job_after_time }.to change { job.reload.updated_at }
          end
        end

        context 'when other state is sent' do
          it "doesn't update update_at value" do
            expect { update_job_after_time(20.minutes, state: 'success') }.not_to change { job.reload.updated_at }
          end
        end
      end

      context 'when job has been erased' do
        let(:job) { create(:ci_build, runner_id: runner.id, erased_at: Time.now) }

        it 'responds with forbidden' do
          update_job

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when job has already been finished' do
        before do
          job.trace.set('Job failed')
          job.drop!(:script_failure)
        end

        it 'does not update job status and job trace' do
          update_job(state: 'success', trace: 'BUILD TRACE UPDATED')

          job.reload
          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.header['Job-Status']).to eq 'failed'
          expect(job.trace.raw).to eq 'Job failed'
          expect(job).to be_failed
        end
      end

      def update_job(token = job.token, **params)
        new_params = params.merge(token: token)
        put api("/jobs/#{job.id}"), params: new_params
      end

      def update_job_after_time(update_interval = 20.minutes, state = 'running')
        Timecop.travel(job.updated_at + update_interval) do
          update_job(job.token, state: state)
        end
      end
    end
  end
end
