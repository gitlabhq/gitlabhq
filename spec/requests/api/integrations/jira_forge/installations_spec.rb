# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Integrations::JiraForge::Installations, :with_current_organization, feature_category: :integrations do
  let_it_be_with_reload(:installation) do
    create(:jira_connect_installation, organization: current_organization, cloud_id: 'cloud-123')
  end

  # A bearer whose header is RS256 + kid, recognized as a FIT (verification stubbed
  # in the before block above).
  let(:fit_headers) do
    header = Base64.urlsafe_encode64({ alg: 'RS256', kid: 'abc' }.to_json, padding: false)
    payload = Base64.urlsafe_encode64({}.to_json, padding: false)

    { 'Authorization' => "Bearer #{header}.#{payload}.signature",
      'X-GitLab-Organization-ID' => current_organization.id.to_s }
  end

  let(:account_id) { 'jira-account-1' }
  let(:jira_admin) { true }
  let(:cloud_id) { 'cloud-123' }
  let(:api_base_url) { 'https://api.atlassian.com/ex/jira/cloud-123' }

  before do
    jira_user = { 'groups' => { 'items' => [{ 'name' => jira_admin ? 'site-admins' : 'users' }] } }

    WebMock
      .stub_request(:get, "#{installation.base_url}/rest/api/3/user?accountId=#{account_id}&expand=groups")
      .to_return(body: jira_user.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })

    # App-context endpoints authenticate by the Forge Invocation Token.
    allow(Atlassian::Forge::InvocationToken).to receive(:new).and_return(
      instance_double(Atlassian::Forge::InvocationToken,
        valid?: true, cloud_id: cloud_id, principal: account_id, api_base_url: api_base_url)
    )
  end

  describe 'Forge Invocation Token audience' do
    let(:setting_ari) { 'ari:cloud:ecosystem::app/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' }
    let(:config_ari) { 'ari:cloud:ecosystem::app/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' }

    let(:verified_token) do
      instance_double(Atlassian::Forge::InvocationToken, valid?: true, cloud_id: cloud_id, principal: account_id)
    end

    it 'verifies against the jira_forge_app_id application setting when set' do
      stub_application_setting(jira_forge_app_id: setting_ari)

      expect(Atlassian::Forge::InvocationToken).to receive(:new)
        .with(anything, audience: setting_ari).and_return(verified_token)

      put api('/integrations/jira_forge/installation'), params: {}, headers: fit_headers

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'falls back to the configured forge_app_id when the setting is blank' do
      stub_application_setting(jira_forge_app_id: nil)
      allow(Gitlab.config.jira_connect).to receive(:forge_app_id).and_return(config_ari)

      expect(Atlassian::Forge::InvocationToken).to receive(:new)
        .with(anything, audience: config_ari).and_return(verified_token)

      put api('/integrations/jira_forge/installation'), params: {}, headers: fit_headers

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'PUT /integrations/jira_forge/installation' do
    subject(:update_installation) do
      put api('/integrations/jira_forge/installation'),
        params: { instance_url: 'https://gitlab.example.com' }, headers: fit_headers
    end

    before do
      # A self-managed instance_url triggers the proxy lifecycle hook (an outbound
      # call to the instance); stub it so the update path can be tested in isolation.
      allow(JiraConnectInstallations::ProxyLifecycleEventService)
        .to receive(:execute).and_return(ServiceResponse.success)
    end

    it 'updates the instance URL' do
      update_installation

      expect(response).to have_gitlab_http_status(:ok)
      expect(installation.reload.instance_url).to eq('https://gitlab.example.com')
    end

    context 'when no instance_url is given (GitLab.com)' do
      before do
        installation.update!(instance_url: 'https://old.example.com')
      end

      it 'clears the instance URL' do
        put api('/integrations/jira_forge/installation'), params: {}, headers: fit_headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(installation.reload.instance_url).to be_nil
      end
    end

    context 'when the Jira user is not an admin' do
      let(:jira_admin) { false }

      it 'returns 403' do
        update_installation

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    it 'rejects a request authenticated only by the cloud-id header' do
      put api('/integrations/jira_forge/installation'),
        params: { instance_url: 'https://gitlab.example.com' },
        headers: { 'X-Gitlab-Jira-Cloud-Id' => 'cloud-123' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the token cloud id matches no installation' do
      let(:cloud_id) { 'unknown-cloud' }

      it 'returns 401' do
        update_installation

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /integrations/jira_forge/installation/forge_token' do
    let(:system_token) { 'system-oauth-token' }
    let(:token_headers) { fit_headers.merge('X-Forge-Oauth-System' => system_token) }

    it 'stores the apiBaseUrl and system token for direct dev-info sync' do
      post api('/integrations/jira_forge/installation/forge_token'), headers: token_headers

      expect(response).to have_gitlab_http_status(:created)
      expect(installation.reload).to have_attributes(
        jira_api_base_url: api_base_url,
        forge_system_token: system_token,
        forge_direct?: true
      )
    end

    it 'returns 400 when the system token header is missing' do
      post api('/integrations/jira_forge/installation/forge_token'), headers: fit_headers

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'rejects a request without a Forge invocation token' do
      post api('/integrations/jira_forge/installation/forge_token'),
        headers: { 'X-Forge-Oauth-System' => system_token, 'X-Gitlab-Jira-Cloud-Id' => 'cloud-123' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end
end
