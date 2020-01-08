# frozen_string_literal: true

require 'spec_helper'

describe 'Self-Monitoring project requests' do
  let(:admin) { create(:admin) }

  describe 'POST #create_self_monitoring_project' do
    let(:worker_class) { SelfMonitoringProjectCreateWorker }

    subject { post create_self_monitoring_project_admin_application_settings_path }

    it_behaves_like 'not accessible to non-admin users'

    context 'with admin user' do
      before do
        login_as(admin)
      end

      context 'with feature flag disabled' do
        it_behaves_like 'not accessible if feature flag is disabled'
      end

      context 'with feature flag enabled' do
        it 'returns sidekiq job_id of expected length' do
          subject

          job_id = json_response['job_id']

          aggregate_failures do
            expect(job_id).to be_present
            expect(job_id.length).to be <= Admin::ApplicationSettingsController::PARAM_JOB_ID_MAX_SIZE
          end
        end

        it 'triggers async worker' do
          expect(worker_class).to receive(:perform_async)

          subject
        end

        it 'returns accepted response' do
          subject

          aggregate_failures do
            expect(response).to have_gitlab_http_status(:accepted)
            expect(json_response.keys).to contain_exactly('job_id', 'monitor_status')
            expect(json_response).to include(
              'monitor_status' => status_create_self_monitoring_project_admin_application_settings_path
            )
          end
        end

        it 'returns job_id' do
          fake_job_id = 'b5b28910d97563e58c2fe55f'
          expect(worker_class).to receive(:perform_async).and_return(fake_job_id)

          subject
          response_job_id = json_response['job_id']

          expect(response_job_id).to eq fake_job_id
        end
      end
    end
  end

  describe 'GET #status_create_self_monitoring_project' do
    let(:worker_class) { SelfMonitoringProjectCreateWorker }
    let(:job_id) { 'job_id' }

    subject do
      get status_create_self_monitoring_project_admin_application_settings_path,
        params: { job_id: job_id }
    end

    it_behaves_like 'not accessible to non-admin users'

    context 'with admin user' do
      before do
        login_as(admin)
      end

      context 'with feature flag disabled' do
        it_behaves_like 'not accessible if feature flag is disabled'
      end

      context 'with feature flag enabled' do
        context 'with invalid job_id' do
          it 'returns bad_request if job_id too long' do
            get status_create_self_monitoring_project_admin_application_settings_path,
              params: { job_id: 'a' * 51 }

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response).to eq('message' => 'Parameter "job_id" cannot ' \
                "exceed length of #{Admin::ApplicationSettingsController::PARAM_JOB_ID_MAX_SIZE}")
            end
          end
        end

        context 'when self-monitoring project exists' do
          let(:project) { build(:project) }

          before do
            stub_application_setting(instance_administration_project_id: 1)
            stub_application_setting(instance_administration_project: project)
          end

          it 'does not need job_id' do
            get status_create_self_monitoring_project_admin_application_settings_path

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:success)
              expect(json_response).to eq(
                'project_id' => 1,
                'project_full_path' => project.full_path
              )
            end
          end

          it 'returns success' do
            subject

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:success)
              expect(json_response).to eq(
                'project_id' => 1,
                'project_full_path' => project.full_path
              )
            end
          end
        end

        context 'when job is in progress' do
          before do
            allow(worker_class).to receive(:in_progress?)
              .with(job_id)
              .and_return(true)
          end

          it 'sets polling header' do
            expect(::Gitlab::PollingInterval).to receive(:set_header)

            subject
          end

          it 'returns accepted' do
            subject

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:accepted)
              expect(json_response).to eq('message' => 'Job is in progress')
            end
          end
        end

        context 'when self-monitoring project and job do not exist' do
          let(:job_id) { nil }

          it 'returns bad_request' do
            subject

            aggregate_failures do
              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response).to eq(
                'message' => 'Self-monitoring project does not exist. Please check ' \
                  'logs for any error messages'
              )
            end
          end
        end
      end
    end
  end
end
