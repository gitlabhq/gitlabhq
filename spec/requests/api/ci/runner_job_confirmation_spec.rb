# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, 'PUT /jobs/:id with job confirmation', feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project, :repository) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }
  let_it_be(:runner, freeze: true) { create(:ci_runner, :project, projects: [project]) }

  let(:job_id) { job.id }
  let(:job_token) { job.token }

  describe 'PUT /api/v4/jobs/:id', :clean_gitlab_redis_cache do
    let(:api_url) { "/api/v4/jobs/#{job_id}" }
    let(:params) { { token: job_token, state: state } }

    subject(:perform_request) do
      put api_url, params: params
    end

    context 'when job is in pending state and assigned to runner' do
      context 'without two-phase commit' do
        let_it_be_with_refind(:runner_manager) { create(:ci_runner_machine, runner: runner, system_xid: 'abc') }

        let!(:job) do
          create(:ci_build, :pending, :queued, pipeline: pipeline, runner: runner, runner_manager: runner_manager)
        end

        context 'when state is pending' do
          let(:state) { 'pending' }

          it 'returns 403 Forbidden' do
            perform_request

            expect(response).to have_gitlab_http_status(:forbidden)
            expect(json_response['message']).to eq('403 Forbidden - Job is not processing on runner')
          end

          it 'does not change job status' do
            expect { perform_request }
              .not_to change { job.reload.status }

            expect(job).to be_pending
          end

          it 'does not update runner heartbeat', :clean_gitlab_redis_cache do
            expect { perform_request }
              .to not_change { runner.reload.contacted_at }
              .and not_change { runner_manager.reload.contacted_at }
          end
        end
      end

      context 'with two-phase commit', :aggregate_failures do
        let_it_be_with_refind(:runner_manager) do
          create(:ci_runner_machine, :two_phase_job_commit_feature, runner: runner, system_xid: 'def')
        end

        let!(:job) { create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner) }

        context 'when state is pending' do
          let(:state) { 'pending' }

          it 'returns 200 OK' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to eq('200')
          end

          it 'does not change job status' do
            expect { perform_request }
              .not_to change { job.reload.status }

            expect(job).to be_pending
          end

          it 'updates runner heartbeat only' do
            expect { perform_request }
              .to change { runner.reload.contacted_at }
              .and not_change { runner_manager.reload.contacted_at }
          end
        end

        context 'when state is running' do
          let(:state) { 'running' }

          it 'transitions job to running state' do
            expect(job.runner_id).to eq(runner.id)

            expect { perform_request }
              .to change { job.reload.status }.from('pending').to('running')
              .and change { job.reload.started_at }
              .and change { job.reload.runner_manager }.from(nil).to(runner_manager)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to eq('200')
          end

          it 'creates running build tracking entry' do
            expect { perform_request }.to change { Ci::RunningBuild.count }.by(1)

            running_build = Ci::RunningBuild.last
            expect(running_build.build_id).to eq(job.id)
            expect(running_build.runner_id).to eq(runner.id)
          end

          it 'sets started_at timestamp', :freeze_time do
            perform_request

            expect(job.reload.started_at).to eq(Time.current)
          end

          context 'when job has moved to running state' do
            before do
              job.run!
              job.runner_manager = runner_manager
            end

            it 'returns 200 OK' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'when job is not assigned to a runner' do
            let!(:job) { create(:ci_build, :pending, pipeline: pipeline, runner: nil) }

            it 'returns 403 Forbidden' do
              perform_request

              expect(response).to have_gitlab_http_status(:forbidden)
              expect(json_response['message']).to eq('403 Forbidden - Job is not processing on runner')
            end
          end
        end

        context 'when state is regular job completion state' do
          let(:state) { 'success' }

          it 'returns 400 Bad Request' do
            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(job.reload).to be_pending
          end
        end
      end

      context 'when allow_runner_job_acknowledgement feature flag is disabled' do
        before do
          stub_feature_flags(allow_runner_job_acknowledgement: false)
        end

        # Even though the FF is disabled, we should still process waiting jobs regardless,
        # so that they don't become zombies
        context 'with two-phase commit setup', :aggregate_failures do
          let_it_be_with_refind(:runner_manager) do
            create(:ci_runner_machine, :two_phase_job_commit_feature, runner: runner, system_xid: 'def')
          end

          let!(:job) { create(:ci_build, :waiting_for_runner_ack, pipeline: pipeline, runner: runner) }

          context 'when state is pending' do
            let(:state) { 'pending' }

            it 'returns 200 OK' do
              perform_request

              expect(response).to have_gitlab_http_status(:ok)
              expect(response.body).to eq('200')
            end

            it 'does not change job status' do
              expect { perform_request }.not_to change { job.reload.status }

              expect(job).to be_pending
            end

            it 'updates runner heartbeat only' do
              expect { perform_request }
                .to change { runner.reload.contacted_at }
                .and not_change { runner_manager.reload.contacted_at }
            end
          end

          context 'when state is running' do
            let(:state) { 'running' }

            it 'transitions job to running state' do
              expect(job.runner_id).to eq(runner.id)

              expect { perform_request }
                .to change { job.reload.status }.from('pending').to('running')
                .and change { job.reload.started_at }
                .and change { job.reload.runner_manager }.from(nil).to(runner_manager)

              expect(response).to have_gitlab_http_status(:ok)
              expect(response.body).to eq('200')
            end

            it 'creates running build tracking entry' do
              expect { perform_request }.to change { Ci::RunningBuild.count }.by(1)

              running_build = Ci::RunningBuild.last
              expect(running_build.build_id).to eq(job.id)
              expect(running_build.runner_id).to eq(runner.id)
            end

            it 'sets started_at timestamp', :freeze_time do
              perform_request

              expect(job.reload.started_at).to eq(Time.current)
            end

            context 'when job has moved to running state' do
              before do
                job.run!
                job.runner_manager = runner_manager
              end

              it 'returns 200 OK' do
                perform_request

                expect(response).to have_gitlab_http_status(:ok)
              end
            end

            context 'when job is not assigned to a runner' do
              let!(:job) { create(:ci_build, :pending, pipeline: pipeline, runner: nil) }

              it 'returns 403 Forbidden' do
                perform_request

                expect(response).to have_gitlab_http_status(:forbidden)
                expect(json_response['message']).to eq('403 Forbidden - Job is not processing on runner')
              end
            end
          end
        end

        context 'without two-phase commit' do
          let_it_be_with_refind(:runner_manager) { create(:ci_runner_machine, runner: runner, system_xid: 'abc') }

          let!(:job) do
            create(:ci_build, :pending, :queued, pipeline: pipeline, runner: runner, runner_manager: runner_manager)
          end

          context 'when state is pending' do
            let(:state) { 'pending' }

            it 'returns 403 Forbidden' do
              perform_request

              expect(response).to have_gitlab_http_status(:forbidden)
              expect(json_response['message']).to eq('403 Forbidden - Job is not processing on runner')
            end
          end
        end
      end
    end

    context 'when token is invalid' do
      let(:params) { { token: '*************', state: 'pending' } }
      let!(:job) do
        create(:ci_build, :pending, pipeline: pipeline, runner: runner, runner_manager: nil)
      end

      it 'returns 403 Forbidden' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when job does not exist' do
      let(:job_id) { non_existing_record_id }
      let(:state) { 'pending' }
      let!(:job) do
        create(:ci_build, :pending, pipeline: pipeline, runner: runner, runner_manager: nil)
      end

      it 'returns 403 Forbidden' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when token is missing' do
      let(:params) { { state: 'pending' } }
      let!(:job) do
        create(:ci_build, :pending, pipeline: pipeline, runner: runner, runner_manager: nil)
      end

      it 'returns 400 Bad Request' do
        perform_request

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
