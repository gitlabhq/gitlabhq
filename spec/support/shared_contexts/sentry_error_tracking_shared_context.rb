# frozen_string_literal: true

RSpec.shared_context 'sentry error tracking context' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:sentry_url) { 'https://sentrytest.gitlab.com/api/0/projects/sentry-org/sentry-project' }
  let(:token) { 'test-token' }
  let(:params) { {} }
  let(:result) { subject.execute }

  let(:error_tracking_setting) do
    create(:project_error_tracking_setting, api_url: sentry_url, token: token, project: project)
  end

  before do
    allow(project).to receive(:error_tracking_setting).at_least(:once).and_return(error_tracking_setting)

    project.add_developer(user)
  end
end
