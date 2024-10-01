# frozen_string_literal: true

RSpec.shared_examples 'logs inbound authorizations via job token' do |success_status, error_status|
  shared_examples 'successfully logs authorization' do
    it 'creates a pipeline and logs the authorization at most once' do
      expect(::Ci::JobToken::Authorization)
        .to receive(:capture)
        .with(origin_project: origin_project, accessed_project: accessed_project)
        .once
        .and_call_original

      expect(Ci::JobToken::LogAuthorizationWorker)
        .to receive(:perform_in).with(5.minutes, accessed_project.id, origin_project.id)

      perform_request

      expect(response).to have_gitlab_http_status(success_status)
    end
  end

  shared_examples 'does not attempt to capture authorization' do |response_status|
    it 'does not log authorizations' do
      expect(Ci::JobToken::LogAuthorizationWorker).not_to receive(:perform_in)

      perform_request

      expect(response).to have_gitlab_http_status(response_status)
    end
  end

  context 'when pipeline is triggered by job token from another project that is allowlisted' do
    let(:token_user) { user }
    let(:job_token) { create(:ci_build, :running, project: origin_project, user: token_user).token }

    before do
      project.ci_cd_settings.update!(inbound_job_token_scope_enabled: true)
      create(:ci_job_token_project_scope_link,
        source_project: accessed_project,
        target_project: origin_project,
        direction: :inbound)
    end

    it_behaves_like 'successfully logs authorization'

    context 'when user is not authorized' do
      let(:token_user) { create(:user) }

      it_behaves_like 'does not attempt to capture authorization', error_status
    end
  end

  context 'when pipeline is triggered by job token from another project that is not allowlisted' do
    let(:job_token) { create(:ci_build, :running, project: origin_project, user: user).token }

    it_behaves_like 'does not attempt to capture authorization', error_status
  end

  context 'when pipeline is triggered by the same project job token' do
    let(:job_token) { create(:ci_build, :running, project: accessed_project, user: user).token }

    it_behaves_like 'does not attempt to capture authorization', success_status
  end

  context 'when pipeline is triggered by another project job token and project scope is disabled' do
    let(:job_token) { create(:ci_build, :running, project: origin_project, user: user).token }

    before do
      accessed_project.ci_cd_settings.update!(inbound_job_token_scope_enabled: false)
    end

    it_behaves_like 'successfully logs authorization'
  end
end
