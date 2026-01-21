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
        context 'with malformed JWT' do
          let(:jwt) { '123' }

          it 'returns 401' do
            post_subscriptions

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response).to eq('message' => '401 Unauthorized - JWT authentication failed')
          end
        end

        context 'with nil JWT' do
          let(:jwt) { nil }

          it 'returns 401' do
            post_subscriptions

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response).to eq('message' => '401 Unauthorized - Invalid JWT token')
          end
        end

        context 'with empty JWT' do
          let(:jwt) { '' }

          it 'returns 401' do
            post_subscriptions

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response).to eq('message' => '401 Unauthorized - Invalid JWT token')
          end
        end

        context 'with oversized JWT' do
          let(:jwt) { 'x' * 9.kilobytes }

          it 'returns 401' do
            post_subscriptions

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response).to eq('message' => '401 Unauthorized - Invalid JWT token')
          end
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

  describe 'POST /api/v4/integrations/jira_connect/subscriptions' do
    let(:installation) { create(:jira_connect_installation) }
    let(:shared_secret) { installation.shared_secret }
    let(:api_path) { '/api/v4/integrations/jira_connect/subscriptions' }

    context 'when installation is not found' do
      it 'returns unauthorized' do
        jwt_token = Atlassian::Jwt.encode({ iss: 'unknown_key' }, 'wrong_secret')
        post api_path, params: { jwt: jwt_token }
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when JWT signature is invalid' do
      it 'returns unauthorized' do
        jwt_token = Atlassian::Jwt.encode({ iss: installation.client_key }, 'wrong_secret')
        post api_path, params: { jwt: jwt_token }
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when user_info call fails' do
      it 'returns error' do
        jwt_token = Atlassian::Jwt.encode(
          { iss: installation.client_key, sub: 'user123', qsh: 'context-qsh' },
          shared_secret
        )

        allow_next_instance_of(Atlassian::JiraConnect::Client) do |instance|
          allow(instance).to receive(:user_info).and_return(nil)
        end

        post api_path, params: { jwt: jwt_token }
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when JWT has valid signature but invalid qsh' do
      it 'returns unauthorized' do
        jwt_token = Atlassian::Jwt.encode(
          { iss: installation.client_key, sub: 'user123', qsh: 'invalid-qsh' },
          shared_secret
        )

        post api_path, params: { jwt: jwt_token }
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
