# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::OauthApplicationIdsController do
  describe 'GET /-/jira_connect/oauth_application_id' do
    before do
      stub_application_setting(jira_connect_application_key: '123456')
    end

    it 'renders the jira connect application id' do
      get '/-/jira_connect/oauth_application_id'

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({ "application_id" => "123456" })
    end

    context 'application ID is empty' do
      before do
        stub_application_setting(jira_connect_application_key: '')
      end

      it 'renders not found' do
        get '/-/jira_connect/oauth_application_id'

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when jira_connect_oauth_self_managed disabled' do
      before do
        stub_feature_flags(jira_connect_oauth_self_managed: false)
      end

      it 'renders not found' do
        get '/-/jira_connect/oauth_application_id'

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
