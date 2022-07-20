# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::OauthApplicationIdsController do
  describe 'OPTIONS /-/jira_connect/oauth_application_id' do
    before do
      stub_application_setting(jira_connect_application_key: '123456')

      options '/-/jira_connect/oauth_application_id', headers: { 'Origin' => 'http://notgitlab.com' }
    end

    it 'returns 200' do
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'allows cross-origin requests', :aggregate_failures do
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, OPTIONS'
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end

    context 'on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'renders not found' do
        options '/-/jira_connect/oauth_application_id'

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.headers['Access-Control-Allow-Origin']).not_to eq '*'
      end
    end
  end

  describe 'GET /-/jira_connect/oauth_application_id' do
    let(:cors_request_headers) { { 'Origin' => 'http://notgitlab.com' } }

    before do
      stub_application_setting(jira_connect_application_key: '123456')
    end

    it 'renders the jira connect application id' do
      get '/-/jira_connect/oauth_application_id'

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({ "application_id" => "123456" })
    end

    it 'allows cross-origin requests', :aggregate_failures do
      get '/-/jira_connect/oauth_application_id', headers: cors_request_headers

      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
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

    context 'when jira_connect_oauth_self_managed disabled' do
      before do
        stub_feature_flags(jira_connect_oauth_self_managed: false)
      end

      it 'renders not found' do
        get '/-/jira_connect/oauth_application_id'

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'renders not found' do
        get '/-/jira_connect/oauth_application_id'

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
