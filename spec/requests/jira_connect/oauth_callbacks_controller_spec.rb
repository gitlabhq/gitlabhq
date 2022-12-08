# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::OauthCallbacksController, feature_category: :integrations do
  describe 'GET /-/jira_connect/oauth_callbacks' do
    context 'when logged in' do
      it 'renders a page prompting the user to close the window' do
        get '/-/jira_connect/oauth_callbacks'

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('You can close this window.')
      end
    end
  end
end
