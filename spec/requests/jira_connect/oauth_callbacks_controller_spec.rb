# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::OauthCallbacksController do
  describe 'GET /-/jira_connect/oauth_callbacks' do
    context 'when logged in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'renders a page prompting the user to close the window' do
        get '/-/jira_connect/oauth_callbacks'

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('You can close this window.')
      end
    end
  end
end
