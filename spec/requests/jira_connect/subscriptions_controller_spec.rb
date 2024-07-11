# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SubscriptionsController, feature_category: :integrations do
  describe 'GET /-/jira_connect/subscriptions' do
    let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'http://self-managed-gitlab.com') }
    let(:qsh) do
      Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test')
    end

    let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }
    let(:cors_request_headers) { { 'Origin' => 'https://gitlab.com' } }
    let(:path) { '/-/jira_connect/subscriptions' }
    let(:params) { { jwt: jwt } }

    before do
      stub_application_setting(jira_connect_proxy_url: 'https://gitlab.com')
    end

    subject(:content_security_policy) do
      get path, params: params, headers: cors_request_headers

      response.headers['Content-Security-Policy']
    end

    it { is_expected.to include('http://self-managed-gitlab.com/-/jira_connect/') }
    it { is_expected.to include('http://self-managed-gitlab.com/api/') }
    it { is_expected.to include('http://self-managed-gitlab.com/oauth/') }
    it { is_expected.to include('frame-ancestors \'self\' https://*.atlassian.net https://*.jira.com') }

    context 'with additional iframe ancestors' do
      before do
        allow(Gitlab.config.jira_connect).to receive(:additional_iframe_ancestors).and_return(['http://localhost:*', 'http://dev.gitlab.com'])
      end

      it {
        is_expected.to include('frame-ancestors \'self\' https://*.atlassian.net https://*.jira.com http://localhost:* http://dev.gitlab.com')
      }
    end

    context 'with no self-managed instance configured' do
      let_it_be(:installation) { create(:jira_connect_installation, instance_url: '') }

      it { is_expected.not_to include('http://self-managed-gitlab.com/-/jira_connect/') }
      it { is_expected.not_to include('http://self-managed-gitlab.com/api/') }
      it { is_expected.not_to include('http://self-managed-gitlab.com/oauth/') }
    end

    context 'when json format' do
      let(:path) { '/-/jira_connect/subscriptions.json' }

      it 'allows cross-origin requests', :aggregate_failures do
        get path, params: params, headers: cors_request_headers

        expect(response.headers['Access-Control-Allow-Origin']).to eq 'https://gitlab.com'
        expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, OPTIONS'
        expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
      end
    end
  end

  describe 'OPTIONS /-/jira_connect/subscriptions' do
    let(:cors_request_headers) { { 'Origin' => 'https://gitlab.com', 'access-control-request-method' => 'GET' } }

    before do
      stub_application_setting(jira_connect_proxy_url: 'https://gitlab.com')
    end

    it 'allows cross-origin requests', :aggregate_failures do
      options '/-/jira_connect/subscriptions.json', headers: cors_request_headers

      expect(response.headers['Access-Control-Allow-Origin']).to eq 'https://gitlab.com'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, OPTIONS'
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end
  end

  describe 'OPTIONS /-/jira_connect/subscriptions/:id' do
    let(:cors_request_headers) { { 'Origin' => 'https://gitlab.com', 'access-control-request-method' => 'DELETE' } }

    before do
      stub_application_setting(jira_connect_proxy_url: 'https://gitlab.com')
    end

    it 'allows cross-origin requests', :aggregate_failures do
      options '/-/jira_connect/subscriptions/1', headers: cors_request_headers

      expect(response.headers['Access-Control-Allow-Origin']).to eq 'https://gitlab.com'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'DELETE, OPTIONS'
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end
  end

  describe 'DELETE /-/jira_connect/subscriptions/:id' do
    let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'http://self-managed-gitlab.com') }
    let_it_be(:subscription) { create(:jira_connect_subscription, installation: installation) }
    let(:stub_service_response) { ::ServiceResponse.success }

    let(:qsh) do
      Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test')
    end

    let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }
    let(:cors_request_headers) { { 'Origin' => 'https://gitlab.com' } }
    let(:params) { { jwt: jwt, format: :json } }

    before do
      stub_application_setting(jira_connect_proxy_url: 'https://gitlab.com')
      allow_next_instance_of(JiraConnectSubscriptions::DestroyService) do |service|
        allow(service).to receive(:execute).and_return(stub_service_response)
      end
    end

    it 'allows cross-origin requests', :aggregate_failures do
      delete "/-/jira_connect/subscriptions/#{subscription.id}", params: params, headers: cors_request_headers

      expect(response.headers['Access-Control-Allow-Origin']).to eq 'https://gitlab.com'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'DELETE, OPTIONS'
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when the service responds with an error' do
      let(:stub_service_response) { ::ServiceResponse.error(message: 'some error', reason: :unprocessable_entity) }

      it 'rejects request with status-code', :aggregate_failures do
        delete "/-/jira_connect/subscriptions/#{subscription.id}", params: params, headers: cors_request_headers

        expect(response.headers['Access-Control-Allow-Origin']).to eq 'https://gitlab.com'
        expect(response.headers['Access-Control-Allow-Methods']).to eq 'DELETE, OPTIONS'
        expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
        expect(response.body).to eq "{\"error\":\"some error\"}"
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end
end
