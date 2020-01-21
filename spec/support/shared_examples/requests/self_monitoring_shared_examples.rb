# frozen_string_literal: true

RSpec.shared_examples 'not accessible if feature flag is disabled' do
  before do
    stub_feature_flags(self_monitoring_project: false)
  end

  it 'returns not_implemented' do
    subject

    aggregate_failures do
      expect(response).to have_gitlab_http_status(:not_implemented)
      expect(json_response).to eq(
        'message' => _('Self-monitoring is not enabled on this GitLab server, contact your administrator.'),
        'documentation_url' => help_page_path('administration/monitoring/gitlab_instance_administration_project/index')
      )
    end
  end
end

RSpec.shared_examples 'not accessible to non-admin users' do
  context 'with unauthenticated user' do
    it 'redirects to signin page' do
      subject

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'with authenticated non-admin user' do
    before do
      login_as(create(:user))
    end

    it 'returns status not_found' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

# Requires subject and worker_class and status_api to be defined
#   let(:worker_class) { SelfMonitoringProjectCreateWorker }
#   let(:status_api) { status_create_self_monitoring_project_admin_application_settings_path }
#   subject { post create_self_monitoring_project_admin_application_settings_path }
RSpec.shared_examples 'triggers async worker, returns sidekiq job_id with response accepted' do
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
        'monitor_status' => status_api
      )
    end
  end

  it 'returns job_id' do
    fake_job_id = 'b5b28910d97563e58c2fe55f'
    allow(worker_class).to receive(:perform_async).and_return(fake_job_id)

    subject

    expect(json_response).to include('job_id' => fake_job_id)
  end
end

# Requires job_id and subject to be defined
#   let(:job_id) { 'job_id' }
#   subject do
#     get status_create_self_monitoring_project_admin_application_settings_path,
#       params: { job_id: job_id }
#   end
RSpec.shared_examples 'handles invalid job_id' do
  context 'with invalid job_id' do
    let(:job_id) { 'a' * 51 }

    it 'returns bad_request if job_id too long' do
      subject

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq('message' => 'Parameter "job_id" cannot ' \
          "exceed length of #{Admin::ApplicationSettingsController::PARAM_JOB_ID_MAX_SIZE}")
      end
    end
  end
end

# Requires in_progress_message and subject to be defined
#   let(:in_progress_message) { 'Job to create self-monitoring project is in progress' }
#   subject do
#     get status_create_self_monitoring_project_admin_application_settings_path,
#       params: { job_id: job_id }
#   end
RSpec.shared_examples 'sets polling header and returns accepted' do
  it 'sets polling header' do
    expect(::Gitlab::PollingInterval).to receive(:set_header)

    subject
  end

  it 'returns accepted' do
    subject

    aggregate_failures do
      expect(response).to have_gitlab_http_status(:accepted)
      expect(json_response).to eq(
        'message' => in_progress_message
      )
    end
  end
end
