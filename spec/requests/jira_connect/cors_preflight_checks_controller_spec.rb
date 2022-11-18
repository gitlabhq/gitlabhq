# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::CorsPreflightChecksController do
  shared_examples 'allows cross-origin requests on self managed' do
    it 'renders not found' do
      options path

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response.headers['Access-Control-Allow-Origin']).to be_nil
    end

    context 'with jira_connect_proxy_url setting' do
      before do
        stub_application_setting(jira_connect_proxy_url: 'https://gitlab.com')

        options path, headers: { 'Origin' => 'http://notgitlab.com' }
      end

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'responds with access-control-allow headers', :aggregate_failures do
        expect(response.headers['Access-Control-Allow-Origin']).to eq 'https://gitlab.com'
        expect(response.headers['Access-Control-Allow-Methods']).to eq allowed_methods
        expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
      end

      context 'when on GitLab.com' do
        before do
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it 'renders not found' do
          options path

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.headers['Access-Control-Allow-Origin']).to be_nil
        end
      end
    end
  end

  describe 'OPTIONS /-/jira_connect/oauth_application_id' do
    let(:allowed_methods) { 'GET, OPTIONS' }
    let(:path) { '/-/jira_connect/oauth_application_id' }

    it_behaves_like 'allows cross-origin requests on self managed'
  end

  describe 'OPTIONS /-/jira_connect/subscriptions.json' do
    let(:allowed_methods) { 'GET, OPTIONS' }
    let(:path) { '/-/jira_connect/subscriptions.json' }

    it_behaves_like 'allows cross-origin requests on self managed'
  end

  describe 'OPTIONS /-/jira_connect/subscriptions/:id' do
    let(:allowed_methods) { 'DELETE, OPTIONS' }
    let(:path) { '/-/jira_connect/subscriptions/123' }

    it_behaves_like 'allows cross-origin requests on self managed'
  end
end
