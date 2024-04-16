# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::WorkspacesController, feature_category: :integrations do
  let_it_be(:installation) { create(:jira_connect_installation) }
  let_it_be(:group) { create(:group, name: 'some-group') }
  let_it_be(:another_group) { create(:group) }

  before do
    create(:jira_connect_subscription, installation: installation, namespace: group)
    create(:jira_connect_subscription, installation: installation, namespace: another_group)
  end

  describe 'GET /-/jira_connect/workspaces/search' do
    before do
      get '/-/jira_connect/workspaces/search', params: { jwt: jwt, searchQuery: search_query }
    end

    let(:search_query) { nil }
    let(:expected_response) do
      {
        'workspaces' => [
          {
            'id' => group.id,
            'name' => group.name,
            'avatarUrl' => group.avatar_url
          }
        ]
      }
    end

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/workspaces/search', 'GET', 'https://gitlab.test') }
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

      context 'without query params' do
        it 'returns 200' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['workspaces'].size).to eq(2)
        end
      end

      context 'with valid query params' do
        let(:search_query) { group.name }

        it 'returns 200' do
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'renders the relevant data as JSON' do
          expect(json_response).to include(expected_response)
        end
      end
    end
  end
end
