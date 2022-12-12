# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Integrations::JiraConnect::Subscriptions, feature_category: :integrations do
  describe 'POST /integrations/jira_connect/subscriptions' do
    subject(:post_subscriptions) { post api('/integrations/jira_connect/subscriptions') }

    it 'returns 401' do
      post_subscriptions

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'with user token' do
      let(:group) { create(:group) }
      let(:user) { create(:user) }

      subject(:post_subscriptions) do
        post api('/integrations/jira_connect/subscriptions', user), params: { jwt: jwt, namespace_path: group.path }
      end

      context 'with invalid JWT' do
        let(:jwt) { '123' }

        it 'returns 401' do
          post_subscriptions

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response).to eq('message' => '401 Unauthorized - JWT authentication failed')
        end
      end

      context 'with valid JWT' do
        let_it_be(:installation) { create(:jira_connect_installation) }
        let_it_be(:user) { create(:user) }

        let(:claims) { { iss: installation.client_key, qsh: 'context-qsh', sub: 1234 } }
        let(:jwt) { Atlassian::Jwt.encode(claims, installation.shared_secret) }
        let(:jira_user) { { 'groups' => { 'items' => [{ 'name' => jira_group_name }] } } }
        let(:jira_group_name) { 'site-admins' }

        before do
          WebMock
            .stub_request(:get, "#{installation.base_url}/rest/api/3/user?accountId=1234&expand=groups")
            .to_return(body: jira_user.to_json, status: 200, headers: { 'Content-Type' => 'application/json' })
        end

        it 'returns 401 if the user does not have access to the group' do
          post_subscriptions

          expect(response).to have_gitlab_http_status(:unauthorized)
        end

        context 'user has access to the group' do
          before do
            group.add_maintainer(user)
          end

          it 'creates a subscription' do
            expect { post_subscriptions }.to change { installation.subscriptions.count }.from(0).to(1)
          end

          it 'returns 201' do
            post_subscriptions

            expect(response).to have_gitlab_http_status(:created)
          end
        end
      end
    end
  end
end
