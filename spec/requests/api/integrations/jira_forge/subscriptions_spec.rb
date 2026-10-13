# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Integrations::JiraForge::Subscriptions, :with_current_organization, feature_category: :integrations do
  let_it_be_with_reload(:installation) do
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
  # verifier resolving to the given cloud id / principal / apiBaseUrl.
  # A format-valid installation ARI per cloud id, derived so that a request for an
  # unknown site also carries an installation id no row holds.
  def installation_ari(cloud_id)
    "ari:cloud:ecosystem::installation/#{Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, cloud_id)}"
  end

  def stub_forge_token(
    cloud_id: 'cloud-123', principal: account_id, api_base_url: nil,
    installation_id: installation_ari(cloud_id))
    allow(Atlassian::Forge::InvocationToken).to receive(:new).and_return(
      instance_double(Atlassian::Forge::InvocationToken,
        valid?: true, installation_id: installation_id, cloud_id: cloud_id,
        principal: principal, api_base_url: api_base_url)
    )
  end

  describe 'POST /integrations/jira_forge/subscriptions' do
    let(:api_base_url) { 'https://api.atlassian.com/ex/jira/cloud-forge' }
    let(:delegation_token) do
      Integrations::JiraForge::UserDelegationToken.build(
        user: user, account_id: account_id, cloud_id: 'cloud-forge'
      ).to_jwt
    end

    let(:forge_link_headers) do
      fit_headers.merge(
        'X-Forge-Oauth-System' => 'sys-token',
        'X-Gitlab-Jira-User-Delegation' => delegation_token
      )
    end

    subject(:create_subscription) do
      post api('/integrations/jira_forge/subscriptions'),
        params: { namespace_path: group.path }, headers: forge_link_headers
    end

    before do
      stub_forge_token(cloud_id: 'cloud-forge', api_base_url: api_base_url)

      # GitLab's own Jira site-admin check, done with the system token that
      # rides the link call.
      WebMock
        .stub_request(:get, "#{api_base_url}/rest/api/3/user?accountId=#{account_id}&expand=groups")
        .to_return(
          body: { 'groups' => { 'items' => [{ 'name' => jira_admin ? 'site-admins' : 'users' }] } }.to_json,
          status: 200, headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'requires a valid Forge invocation token' do
      post api('/integrations/jira_forge/subscriptions'),
        params: { namespace_path: group.path },
        headers: forge_link_headers.except('Authorization')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the system token header is missing' do
      before_all { group.add_maintainer(user) }

      it 'returns 400' do
        post api('/integrations/jira_forge/subscriptions'),
          params: { namespace_path: group.path },
          headers: forge_link_headers.except('X-Forge-Oauth-System')

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when the user delegation token is missing' do
      it 'returns 401' do
        post api('/integrations/jira_forge/subscriptions'),
          params: { namespace_path: group.path },
          headers: forge_link_headers.except('X-Gitlab-Jira-User-Delegation')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the user delegation token is expired' do
      before_all { group.add_maintainer(user) }

      it 'returns 401 and creates no installation' do
        expired = delegation_token

        travel_to((Integrations::JiraForge::UserDelegationToken::EXPIRE_TIME + 2.minutes).from_now) do
          expect do
            post api('/integrations/jira_forge/subscriptions'),
              params: { namespace_path: group.path },
              headers: fit_headers.merge(
                'X-Forge-Oauth-System' => 'sys-token', 'X-Gitlab-Jira-User-Delegation' => expired
              )
          end.not_to change { JiraConnectInstallation.count }
        end

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the delegation token was minted for a different Jira site' do
      let(:delegation_token) do
        Integrations::JiraForge::UserDelegationToken.build(
          user: user, account_id: account_id, cloud_id: 'other-cloud'
        ).to_jwt
      end

      before_all { group.add_maintainer(user) }

      it 'returns 401 and creates no installation' do
        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the delegation token was minted for a different Jira account' do
      let(:delegation_token) do
        Integrations::JiraForge::UserDelegationToken.build(
          user: user, account_id: 'other-account', cloud_id: 'cloud-forge'
        ).to_jwt
      end

      before_all { group.add_maintainer(user) }

      it 'returns 401 and creates no installation' do
        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the delegated user is blocked' do
      let_it_be(:blocked_user) { create(:user, :blocked) }
      let(:delegation_token) do
        Integrations::JiraForge::UserDelegationToken.build(
          user: blocked_user, account_id: account_id, cloud_id: 'cloud-forge'
        ).to_jwt
      end

      it 'returns 401 and creates no installation' do
        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the Jira user is not an admin' do
      let(:jira_admin) { false }

      before_all { group.add_maintainer(user) }

      it 'returns 403 and creates no installation' do
        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when Jira does not return the user' do
      before_all { group.add_maintainer(user) }

      it 'returns 403 and creates no installation' do
        WebMock
          .stub_request(:get, "#{api_base_url}/rest/api/3/user?accountId=#{account_id}&expand=groups")
          .to_return(status: 404)

        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the namespace has no installation yet' do
      before_all { group.add_maintainer(user) }

      it 'creates a forge_direct? installation on the namespace organization and links it' do
        expect { create_subscription }.to change { JiraConnectInstallation.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)

        created = JiraConnectInstallation.find_by(cloud_id: 'cloud-forge')
        expect(created).to have_attributes(
          organization_id: group.organization_id,
          client_key: nil,
          jira_api_base_url: api_base_url,
          forge_system_token: 'sys-token'
        )
        expect(created.forge?).to be(true)
        expect(created.forge_direct?).to be(true)
        expect(created.subscriptions.count).to eq(1)
        expect(json_response['organization_id']).to eq(group.organization_id)
      end
    end

    context 'when a Connect installation already exists (upgrade path)' do
      let_it_be(:existing) do
        create(:jira_connect_installation, organization_id: group.organization_id, cloud_id: 'cloud-forge')
      end

      before_all { group.add_maintainer(user) }

      it 'reuses the existing installation, which becomes forge_direct?' do
        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:created)
        expect(existing.reload.forge_direct?).to be(true)
        expect(existing.subscriptions.count).to eq(1)
      end

      context 'when the Forge context cannot be stored' do
        before do
          allow_next_found_instance_of(JiraConnectInstallation) do |found|
            allow(found).to receive(:update).and_call_original
            allow(found).to receive(:update).with(hash_including(:forge_system_token)) do
              found.errors.add(:jira_api_base_url, 'is blocked')
              false
            end
          end
        end

        it 'returns 422 and links nothing' do
          expect { create_subscription }.not_to change { JiraConnectSubscription.count }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(existing.reload.forge_direct?).to be(false)
        end
      end
    end

    context 'when the delegated user is not allowed to use the API' do
      before_all { group.add_maintainer(user) }

      before do
        allow_next_instance_of(Gitlab::UserAccess) do |access|
          allow(access).to receive(:allowed?).and_return(false)
        end
      end

      it 'returns 401 and creates no installation' do
        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when linking a second group to an installation that already has one' do
      let_it_be(:second_group) { create(:group) }
      let_it_be(:existing) do
        create(:jira_connect_installation, :forge, organization_id: group.organization_id, cloud_id: 'cloud-forge',
          forge_installation_xid: installation_ari('cloud-forge'))
      end

      subject(:link_second_group) do
        post api('/integrations/jira_forge/subscriptions'),
          params: { namespace_path: second_group.path }, headers: forge_link_headers
      end

      before_all do
        create(:jira_connect_subscription, installation: existing, namespace: group)
        second_group.add_maintainer(user)
      end

      it 'reuses the installation and links the second group without creating a duplicate' do
        expect { link_second_group }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:created)
        expect(existing.subscriptions.map(&:namespace_id)).to contain_exactly(group.id, second_group.id)
      end
    end

    context 'when the namespace belongs to another organization' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:foreign_group) { create(:group, organization: other_organization) }
      let_it_be(:existing) do
        create(:jira_connect_installation, :forge, organization_id: group.organization_id,
          cloud_id: 'cloud-forge', forge_installation_xid: installation_ari('cloud-forge'))
      end

      before_all do
        create(:jira_connect_subscription, installation: existing, namespace: group)
        foreign_group.add_maintainer(user)
      end

      it 'refuses the link and creates no subscription' do
        expect do
          post api('/integrations/jira_forge/subscriptions'),
            params: { namespace_path: foreign_group.path }, headers: forge_link_headers
        end.not_to change { JiraConnectSubscription.count }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq('This group cannot be linked to this Jira site.')
      end
    end

    context 'when the user cannot link the namespace' do
      before_all { group.add_developer(user) }

      it 'returns 403 and creates no installation' do
        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the namespace is not visible to the user' do
      let_it_be(:private_group) { create(:group, :private) }

      subject(:create_subscription) do
        post api('/integrations/jira_forge/subscriptions'),
          params: { namespace_path: private_group.path }, headers: forge_link_headers
      end

      it 'returns 404 and creates no installation' do
        expect { create_subscription }.not_to change { JiraConnectInstallation.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /integrations/jira_forge/user_delegation' do
    let_it_be(:oauth_token) { create(:oauth_access_token, resource_owner: user, scopes: [:api]) }
    let(:params) { { account_id: account_id, cloud_id: 'cloud-forge' } }

    it 'mints a scoped delegation token for the OAuth-authenticated GitLab user' do
      post api('/integrations/jira_forge/user_delegation', oauth_access_token: oauth_token), params: params

      expect(response).to have_gitlab_http_status(:created)

      delegation = Integrations::JiraForge::UserDelegationToken.decode(json_response['delegation'])
      expect(delegation).to have_attributes(user_id: user.id, account_id: account_id, cloud_id: 'cloud-forge')
    end

    it 'requires GitLab user authentication' do
      post api('/integrations/jira_forge/user_delegation'), params: params

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'rejects a personal access token' do
      post api('/integrations/jira_forge/user_delegation', user), params: params

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'rejects an OAuth token without the api scope' do
      read_only = create(:oauth_access_token, resource_owner: user, scopes: [:read_user])

      post api('/integrations/jira_forge/user_delegation', oauth_access_token: read_only), params: params

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'requires the scope params' do
      post api('/integrations/jira_forge/user_delegation', oauth_access_token: oauth_token), params: {}

      expect(response).to have_gitlab_http_status(:bad_request)
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

    it 'backfills the Forge installation id on a Connect row on first contact' do
      stub_forge_token

      expect { get api('/integrations/jira_forge/subscriptions'), headers: fit_headers }
        .to change { installation.reload.forge_installation_xid }.from(nil).to(installation_ari('cloud-123'))
    end

    it 'resolves an installation that already carries the Forge installation id' do
      installation.update!(forge_installation_xid: installation_ari('cloud-123'))
      stub_forge_token

      get api('/integrations/jira_forge/subscriptions'), headers: fit_headers

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['subscriptions'].size).to eq(1)
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

    it 'resolves an installation that already carries the Forge installation id' do
      installation.update!(forge_installation_xid: installation_ari('cloud-123'))
      stub_forge_token

      expect do
        delete api("/integrations/jira_forge/subscriptions/#{subscription.id}"), headers: fit_headers
      end.to change { installation.subscriptions.count }.by(-1)

      expect(response).to have_gitlab_http_status(:ok)
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
