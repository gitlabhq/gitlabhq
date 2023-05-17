# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::OauthApplicationIdsController, feature_category: :integrations do
  describe 'GET /-/jira_connect/oauth_application_id' do
    let(:cors_request_headers) { { 'Origin' => 'https://gitlab.com' } }

    before do
      stub_application_setting(jira_connect_application_key: '123456')
      stub_application_setting(jira_connect_proxy_url: 'https://gitlab.com')
    end

    it 'renders the jira connect application id' do
      get '/-/jira_connect/oauth_application_id'

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({ "application_id" => "123456" })
    end

    it 'allows cross-origin requests', :aggregate_failures do
      get '/-/jira_connect/oauth_application_id', headers: cors_request_headers

      expect(response.headers['Access-Control-Allow-Origin']).to eq 'https://gitlab.com'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, OPTIONS'
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
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

    context 'on SaaS', :saas do
      it 'renders not found' do
        get '/-/jira_connect/oauth_application_id'

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'OPTIONS /-/jira_connect/oauth_application_id' do
    let(:cors_request_headers) { { 'Origin' => 'https://gitlab.com', 'access-control-request-method' => 'GET' } }

    before do
      stub_application_setting(jira_connect_application_key: '123456')
      stub_application_setting(jira_connect_proxy_url: 'https://gitlab.com')
    end

    it 'allows cross-origin requests', :aggregate_failures do
      options '/-/jira_connect/oauth_application_id', headers: cors_request_headers

      expect(response.headers['Access-Control-Allow-Origin']).to eq 'https://gitlab.com'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, OPTIONS'
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end
  end
end
