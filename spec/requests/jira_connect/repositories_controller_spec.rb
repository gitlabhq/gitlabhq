# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::RepositoriesController, feature_category: :integrations do
  let_it_be(:installation) { create(:jira_connect_installation) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :small_repo, namespace: group) }

  let(:expected_response) do
    {
      'id' => project.id,
      'name' => project.name,
      'avatarUrl' => project.avatar_url,
      'url' => Gitlab::Utils.append_path(Settings.gitlab.base_url.chomp('/'), project_path(project)),
      'lastUpdatedDate' => project.updated_at.iso8601,
      'updateSequenceId' => be_a(Integer),
      'workspace' => {
        'id' => project.namespace_id,
        'name' => project.namespace.name,
        'avatarUrl' => project.namespace.avatar_url
      }
    }
  end

  before do
    create(:project, :small_repo, namespace: group, name: 'some-project')
    create(:jira_connect_subscription, installation: installation, namespace: group)
  end

  describe 'GET /-/jira_connect/repositories/search' do
    before do
      get '/-/jira_connect/repositories/search', params: { jwt: jwt, searchQuery: search_query }
    end

    let(:search_query) { nil }

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/repositories/search', 'GET', 'https://gitlab.test') }
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

      context 'without query params' do
        it 'returns 200' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['containers'].size).to eq(2)
        end
      end

      context 'with query params' do
        let(:search_query) { project.name.chop }

        it 'returns 200' do
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'renders the relevant data as JSON' do
          expect(json_response).to include('containers' => [expected_response])
        end
      end
    end
  end

  describe 'POST /-/jira_connect/repositories/associate' do
    before do
      post '/-/jira_connect/repositories/associate', params: { jwt: jwt, id: id }
    end

    let(:id) { nil }

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/repositories/associate', 'POST', 'https://gitlab.test') }
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

      context 'with invalid ID' do
        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with valid ID' do
        let(:id) { project.id }

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
