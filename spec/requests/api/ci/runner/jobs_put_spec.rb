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
    let_it_be(:group) { create(:group, :nested) }
    let_it_be(:project) { create(:project, namespace: group, shared_runners_enabled: false) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master') }
    let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
    let_it_be(:user) { create(:user) }

    describe 'PUT /api/v4/jobs/:id' do
      let_it_be_with_reload(:job) do
        create(:ci_build, :pending, :trace_live, pipeline: pipeline, project: project, user: user, runner_id: runner.id)
      end

      before do
        job.run!
      end

      it_behaves_like 'API::CI::Runner application context metadata', 'PUT /api/:version/jobs/:id' do
        let(:send_request) { update_job(state: 'success') }
      end

      it 'updates runner info' do
        expect { update_job(state: 'success') }.to change { runner.reload.contacted_at }
      end

      context 'when status is given' do
        it 'marks job as succeeded' do
          update_job(state: 'success')

          expect(job.reload).to be_success
          expect(response.header).not_to have_key('X-GitLab-Trace-Update-Interval')
        end

        it 'marks job as failed' do
          update_job(state: 'failed')

          expect(job.reload).to be_failed
          expect(job).to be_unknown_failure
          expect(response.header).not_to have_key('X-GitLab-Trace-Update-Interval')
        end

        context 'when runner sends an unrecognized field in a payload' do
          ##
          # This test case is here to ensure that the API used to communicate
          # runner with GitLab can evolve.
          #
          # In case of adding new features on the Runner side we do not want
          # GitLab-side to reject requests containing unrecognizable fields in
          # a payload, because runners can be updated before a new version of
          # GitLab is installed.
          #
          it 'ignores unrecognized fields' do
            update_job(state: 'success', 'unknown': 'something')

            expect(job.reload).to be_success
          end
        end

        context 'when an exit_code is provided' do
          context 'when the exit_codes are acceptable' do
            before do
              job.options[:allow_failure_criteria] = { exit_codes: [1] }
              job.save!
            end

            it 'accepts an exit code' do
              update_job(state: 'failed', exit_code: 1)

              expect(job.reload).to be_failed
              expect(job.allow_failure).to be_truthy
              expect(job).to be_unknown_failure
            end
          end

          context 'when the exit_codes are not defined' do
            it 'ignore the exit code' do
              update_job(state: 'failed', exit_code: 1)

              expect(job.reload).to be_failed
              expect(job.allow_failure).to be_falsy
              expect(job).to be_unknown_failure
            end
          end
        end

        context 'when failure_reason is script_failure' do
          before do
            update_job(state: 'failed', failure_reason: 'script_failure')
          end

          it { expect(job.reload).to be_script_failure }
        end

        context 'when failure_reason is runner_system_failure' do
          before do
            update_job(state: 'failed', failure_reason: 'runner_system_failure')
          end

          it { expect(job.reload).to be_runner_system_failure }
        end

        context 'when failure_reason is unrecognized value' do
          before do
            update_job(state: 'failed', failure_reason: 'what_is_this')
          end

          it { expect(job.reload).to be_unknown_failure }
        end

        context 'when failure_reason is job_execution_timeout' do
          before do
            update_job(state: 'failed', failure_reason: 'job_execution_timeout')
          end

          it { expect(job.reload).to be_job_execution_timeout }
        end

        context 'when failure_reason is unmet_prerequisites' do
          before do
            update_job(state: 'failed', failure_reason: 'unmet_prerequisites')
          end

          it { expect(job.reload).to be_unmet_prerequisites }
        end

        context 'when unmigrated live trace chunks exist' do
          context 'when accepting trace feature is enabled' do
            before do
              stub_feature_flags(ci_accept_trace: true)
            end

            context 'when checksum is present' do
              context 'when live trace chunk is still live' do
                it 'responds with 202' do
                  update_job(state: 'success', checksum: 'crc32:12345678')

                  expect(job.pending_state).to be_present
                  expect(response).to have_gitlab_http_status(:accepted)
                  expect(response.header['X-GitLab-Trace-Update-Interval']).to be > 0
                end
              end

              context 'when runner retries request after receiving 202' do
                it 'responds with 202 and then with 200', :sidekiq_inline do
                  update_job(state: 'success', checksum: 'crc32:12345678')

                  expect(response).to have_gitlab_http_status(:accepted)
                  expect(job.reload.pending_state).to be_present

                  update_job(state: 'success', checksum: 'crc32:12345678')

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(job.reload.pending_state).not_to be_present
                end
              end

              context 'when live trace chunk has been migrated' do
                before do
                  job.trace_chunks.first.update!(data_store: :database)
                end

                it 'responds with 200' do
                  update_job(state: 'success', checksum: 'crc:12345678')

                  expect(job.reload).to be_success
                  expect(job.pending_state).to be_present
                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response.header).not_to have_key('X-GitLab-Trace-Update-Interval')
                end
              end
            end

            context 'when checksum is not present' do
              it 'responds with 200' do
                update_job(state: 'success')

                expect(job.reload).to be_success
                expect(job.pending_state).not_to be_present
                expect(response).to have_gitlab_http_status(:ok)
              end
            end
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

        it 'does not update job status' do
          update_job(state: 'success')

          job.reload
          expect(response).to have_gitlab_http_status(:forbidden)
          expect(response.header['Job-Status']).to eq 'failed'
          expect(job).to be_failed
        end
      end

      context 'when job does not exist anymore' do
        it 'returns 403 Forbidden' do
          update_job(non_existing_record_id, state: 'success')

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      def update_job(job_id = job.id, token = job.token, **params)
        new_params = params.merge(token: token)
        put api("/jobs/#{job_id}"), params: new_params
      end

      def update_job_after_time(update_interval = 20.minutes, state = 'running')
        travel_to(job.updated_at + update_interval) do
          update_job(job.id, job.token, state: state)
        end
      end
    end
  end
end
