# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::InstallationsController, :with_current_organization, feature_category: :integrations do
  let_it_be(:installation) { create(:jira_connect_installation, organization: current_organization) }

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
        let_it_be(:installation) do
          create(:jira_connect_installation, instance_url: 'https://example.com', organization: current_organization)
        end

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
    subject(:do_request) do
      put '/-/jira_connect/installations', params: { jwt: jwt, installation: { instance_url: update_instance_url } }
    end

    let(:update_instance_url) { nil }

    context 'without JWT' do
      let(:jwt) { nil }

      it 'returns 403' do
        do_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'with valid JWT' do
      let(:qsh) { Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test') }
      let(:jwt) do
        Atlassian::Jwt.encode(
          { iss: installation.client_key, qsh: qsh, sub: 'jira_user_id' },
          installation.shared_secret
        )
      end

      before do
        allow_next_instance_of(Atlassian::JiraConnect::Client) do |client|
          allow(client).to receive(:user_info).with('jira_user_id').and_return(
            Atlassian::JiraConnect::JiraUser.new({ 'groups' => { 'items' => [{ 'name' => 'site-admins' }] } })
          )
        end
      end

      it 'returns 200' do
        do_request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'passes jira_user and current organization id to UpdateService' do
        expect(JiraConnectInstallations::UpdateService)
          .to receive(:execute)
          .with(
            installation,
            instance_of(Atlassian::JiraConnect::JiraUser),
            ActionController::Parameters
              .new(instance_url: nil, organization_id: current_organization.id)
              .permit(:instance_url, :organization_id))
          .and_call_original

        do_request
      end

      context 'when jira user is not an admin' do
        before do
          allow_next_instance_of(Atlassian::JiraConnect::Client) do |client|
            allow(client).to receive(:user_info).with('jira_user_id').and_return(
              Atlassian::JiraConnect::JiraUser.new({ 'groups' => { 'items' => [{ 'name' => 'regular-users' }] } })
            )
          end
        end

        it 'returns 403' do
          do_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when JWT has no sub claim' do
        let(:jwt) do
          Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret)
        end

        it 'returns 403' do
          do_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with instance_url param' do
        let(:update_instance_url) { 'https://example.com' }

        context 'instance response with success' do
          before do
            stub_request(:post, 'https://example.com/-/jira_connect/events/installed')
          end

          it 'updates the instance_url' do
            do_request

            expect(json_response).to eq({
              'gitlab_com' => false,
              'instance_url' => 'https://example.com'
            })
          end

          it 'sends an installed event to the self-managed instance' do
            do_request

            expect(WebMock).to have_requested(:post, 'https://example.com/-/jira_connect/events/installed')
          end
        end

        context 'instance response with error' do
          before do
            stub_request(:post, 'https://example.com/-/jira_connect/events/installed').to_return(status: 422)
          end

          it 'returns 422 and errors', :aggregate_failures do
            do_request

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response).to eq(
              { 'errors' => 'Could not be installed on the instance. Error response code 422' }
            )
          end
        end

        context 'invalid URL' do
          let(:update_instance_url) { 'invalid url' }

          it 'returns 422 and errors', :aggregate_failures do
            do_request

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
end
