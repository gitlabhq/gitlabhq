# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::InstallationsController, feature_category: :integrations do
  let_it_be(:installation) { create(:jira_connect_installation) }

  describe 'GET /-/jira_connect/installations' do
    before do
      get '/-/jira_connect/installations', params: { jwt: jwt }
    end

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/installations', 'GET', 'https://gitlab.test') }
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

      it 'returns status ok' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns the installation as json' do
        expect(json_response).to eq({
          'gitlab_com' => true,
          'instance_url' => nil
        })
      end

      context 'with instance_url' do
        let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'https://example.com') }

        it 'returns the installation as json' do
          expect(json_response).to eq({
            'gitlab_com' => false,
            'instance_url' => 'https://example.com'
          })
        end
      end
    end
  end

  describe 'PUT /-/jira_connect/installations' do
    before do
      put '/-/jira_connect/installations', params: { jwt: jwt, installation: { instance_url: update_instance_url } }
    end

    let(:update_instance_url) { 'https://example.com' }

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test') }
      let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'updates the instance_url' do
        expect(json_response).to eq({
          'gitlab_com' => false,
          'instance_url' => 'https://example.com'
        })
      end

      context 'invalid URL' do
        let(:update_instance_url) { 'invalid url' }

        it 'returns 422 and errors', :aggregate_failures do
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response).to eq({
            'errors' => {
              'instance_url' => [
                'is blocked: Only allowed schemes are http, https'
              ]
            }
          })
        end
      end
    end
  end
end
