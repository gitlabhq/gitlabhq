# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::UsersController, feature_category: :integrations do
  describe 'GET /-/jira_connect/users' do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    context 'with a valid host' do
      let(:return_to) { 'https://testcompany.atlassian.net/plugins/servlet/ac/gitlab-jira-connect-staging.gitlab.com/gitlab-configuration' }

      it 'includes a return url' do
        get '/-/jira_connect/users', params: { return_to: return_to }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('Return to GitLab')
      end
    end

    context 'with an invalid host' do
      let(:return_to) { 'https://evil.com' }

      it 'does not include a return url' do
        get '/-/jira_connect/users', params: { return_to: return_to }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to include('Return to GitLab')
      end
    end

    context 'with a script injected' do
      let(:return_to) { 'javascript://test.atlassian.net/%250dalert(document.domain)' }

      it 'does not include a return url' do
        get '/-/jira_connect/users', params: { return_to: return_to }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to include('Return to GitLab')
      end
    end
  end
end
