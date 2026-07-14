# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Integrations::JiraForge::Subscriptions, :with_current_organization, feature_category: :integrations do
  let_it_be(:installation) do
    create(:jira_connect_installation, organization: current_organization, cloud_id: 'cloud-123')
  end

  let(:fit_headers) do
    header = Base64.urlsafe_encode64({ alg: 'RS256', kid: 'abc' }.to_json, padding: false)
    payload = Base64.urlsafe_encode64({}.to_json, padding: false)

    { 'Authorization' => "Bearer #{header}.#{payload}.signature",
      'X-GitLab-Organization-ID' => current_organization.id.to_s }
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:account_id) { 'jira-account-1' }
  let(:jira_admin) { true }

  before do
    jira_user = { 'groups' => { 'items' => [{ 'name' => jira_admin ? 'site-admins' : 'users' }] } }

    WebMock
      .stub_request(:get, "#{installation.base_url}/rest/api/3/user?accountId=#{account_id}&expand=groups")
      .to_return(body: jira_user.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
  end

  # Authenticate an app-context request with a (stubbed) Forge Invocation Token:
  # a bearer whose header is RS256 + kid (recognized as a FIT) plus a stub of the
  # verifier resolving to the given cloud id / principal.
  def stub_forge_token(cloud_id: 'cloud-123', principal: account_id)
    allow(Atlassian::Forge::InvocationToken).to receive(:new).and_return(
      instance_double(Atlassian::Forge::InvocationToken, valid?: true, cloud_id: cloud_id, principal: principal)
    )
  end

  describe 'POST /integrations/jira_forge/subscriptions' do
    let(:cloud_id) { 'cloud-123' }
    let(:forge_headers) { { 'X-Gitlab-Jira-Cloud-Id' => cloud_id, 'X-Gitlab-Jira-Account-Id' => account_id } }

    subject(:create_subscription) do
      post api('/integrations/jira_forge/subscriptions', user),
        params: { namespace_path: group.path }, headers: forge_headers
    end

    it 'requires GitLab user authentication' do
      post api('/integrations/jira_forge/subscriptions'),
        params: { namespace_path: group.path }, headers: forge_headers

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the cloud id matches no installation' do
      let(:cloud_id) { 'unknown-cloud' }

      it 'returns 401' do
        create_subscription

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the user is a maintainer and the Jira user is an admin' do
      before_all do
        group.add_maintainer(user)
      end

      it 'creates the subscription and returns the organization id' do
        expect { create_subscription }.to change { installation.subscriptions.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['organization_id']).to eq(current_organization.id)
      end
    end

    context 'when the Jira user is not an admin' do
      let(:jira_admin) { false }

      before_all do
        group.add_maintainer(user)
      end

      it 'returns 403' do
        create_subscription

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the user cannot link the namespace' do
      before_all do
        group.add_developer(user)
      end

      it 'returns 403' do
        create_subscription

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /integrations/jira_forge/subscriptions' do
    let_it_be(:subscription) { create(:jira_connect_subscription, installation: installation, namespace: group) }

    it 'lists the subscriptions for the installation (FIT-authenticated)' do
      stub_forge_token

      get api('/integrations/jira_forge/subscriptions'), headers: fit_headers

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['subscriptions'].size).to eq(1)
    end

    it 'rejects a request authenticated only by the cloud-id header' do
      get api('/integrations/jira_forge/subscriptions'), headers: { 'X-Gitlab-Jira-Cloud-Id' => 'cloud-123' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the token cloud id matches no installation' do
      it 'returns 401' do
        stub_forge_token(cloud_id: 'unknown-cloud')

        get api('/integrations/jira_forge/subscriptions'), headers: fit_headers

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /integrations/jira_forge/subscriptions/:id' do
    let_it_be_with_reload(:subscription) do
      create(:jira_connect_subscription, installation: installation, namespace: group)
    end

    it 'destroys the subscription (FIT-authenticated)' do
      stub_forge_token

      expect do
        delete api("/integrations/jira_forge/subscriptions/#{subscription.id}"), headers: fit_headers
      end.to change { installation.subscriptions.count }.by(-1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'rejects a request authenticated only by the cloud-id header' do
      delete api("/integrations/jira_forge/subscriptions/#{subscription.id}"),
        headers: { 'X-Gitlab-Jira-Cloud-Id' => 'cloud-123' }

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the subscription does not exist' do
      it 'returns 404' do
        stub_forge_token

        delete api('/integrations/jira_forge/subscriptions/0'), headers: fit_headers

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the Jira user is not an admin' do
      let(:jira_admin) { false }

      it 'returns 403' do
        stub_forge_token

        delete api("/integrations/jira_forge/subscriptions/#{subscription.id}"), headers: fit_headers

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
