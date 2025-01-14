# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Integrations, feature_category: :integrations do
  include Integrations::TestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, creator_id: user.id, namespace: user.namespace) }

  let_it_be(:available_integration_names) do
    excluded_integrations = [Integrations::GitlabSlackApplication.to_param, Integrations::Zentao.to_param]

    Integration.available_integration_names(include_instance_specific: false) - excluded_integrations
  end

  let_it_be(:project_integrations_map) do
    available_integration_names.index_with do |name|
      create(integration_factory(name), :inactive, project: project)
    end
  end

  let_it_be(:project2) { create(:project, creator_id: user.id, namespace: user.namespace) }

  %w[integrations services].each do |endpoint|
    describe "GET /projects/:id/#{endpoint}" do
      it 'returns authentication error when unauthenticated' do
        get api("/projects/#{project.id}/#{endpoint}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it "returns error when authenticated but user is not a project owner" do
        project.add_developer(user2)
        get api("/projects/#{project.id}/#{endpoint}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'with integrations' do
        it "returns a list of all active integrations" do
          get api("/projects/#{project.id}/#{endpoint}", user)

          aggregate_failures 'expect successful response with all active integrations' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to be_an Array
            expect(json_response.count).to eq(1)
            expect(json_response.first['slug']).to eq('prometheus')
            expect(response).to match_response_schema('public_api/v4/integrations')
          end
        end
      end
    end

    where(:integration) do
      # The integrations API supports all project integrations.
      # You cannot create a GitLab for Slack app. You must install the app from the GitLab UI.
      unavailable_integration_names = [
        Integrations::GitlabSlackApplication.to_param,
        Integrations::JiraCloudApp.to_param,
        Integrations::Prometheus.to_param,
        Integrations::Zentao.to_param
      ]

      names = Integration.available_integration_names(include_instance_specific: false)
      names.reject { |name| name.in?(unavailable_integration_names) }
    end

    with_them do
      integration = params[:integration]

      describe "PUT /projects/:id/#{endpoint}/#{integration.dasherize}" do
        it_behaves_like 'set up an integration', endpoint: endpoint, integration: integration
      end

      describe "DELETE /projects/:id/#{endpoint}/#{integration.dasherize}" do
        it_behaves_like 'disable an integration', endpoint: endpoint, integration: integration
      end

      describe "GET /projects/:id/#{endpoint}/#{integration.dasherize}" do
        it_behaves_like 'get an integration settings', endpoint: endpoint, integration: integration
      end
    end

    describe "POST /projects/:id/#{endpoint}/:slug/trigger" do
      describe 'Mattermost integration' do
        let(:integration_name) { 'mattermost_slash_commands' }

        context 'when no integration is available' do
          it 'returns a not found message' do
            post api("/projects/#{project.id}/#{endpoint}/idonotexist/trigger")

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response["error"]).to eq("404 Not Found")
          end
        end

        context 'when the integration exists' do
          let(:params) { { token: 'secrettoken' } }

          context 'when the integration is not active' do
            before do
              project_integrations_map[integration_name].deactivate!
            end

            it 'when the integration is inactive' do
              post api("/projects/#{project.id}/#{endpoint}/#{integration_name}/trigger"), params: params

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when the integration is active' do
            before do
              project_integrations_map[integration_name].activate!
            end

            it 'returns status 200' do
              post api("/projects/#{project.id}/#{endpoint}/#{integration_name}/trigger"), params: params

              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          context 'when the project can not be found' do
            it 'returns a generic 404' do
              post api("/projects/404/#{endpoint}/#{integration_name}/trigger"), params: params

              expect(response).to have_gitlab_http_status(:not_found)
              expect(json_response["message"]).to eq("404 Integration Not Found")
            end
          end
        end
      end

      describe 'Slack Integration' do
        let(:integration_name) { 'slack_slash_commands' }
        let(:params) { { token: 'secrettoken', text: 'help' } }

        context 'when no integration is available' do
          it 'returns a not found message' do
            post api("/projects/#{project.id}/#{endpoint}/idonotexist/trigger")

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response["error"]).to eq("404 Not Found")
          end
        end

        context 'when the integration exists' do
          context 'when the integration is not active' do
            before do
              project_integrations_map[integration_name].deactivate!
            end

            it 'when the integration is inactive' do
              post api("/projects/#{project.id}/#{endpoint}/#{integration_name}/trigger"), params: params

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when the integration is active' do
            before do
              project_integrations_map[integration_name].activate!
            end

            it 'returns status 200' do
              post api("/projects/#{project.id}/#{endpoint}/#{integration_name}/trigger"), params: params

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response['response_type']).to eq("ephemeral")
            end
          end

          context 'when the project can not be found' do
            it 'returns a generic 404' do
              post api("/projects/404/#{endpoint}/#{integration_name}/trigger"), params: params

              expect(response).to have_gitlab_http_status(:not_found)
              expect(json_response["message"]).to eq("404 Integration Not Found")
            end
          end
        end
      end
    end

    describe 'Mattermost integration' do
      let(:integration_name) { 'mattermost' }
      let(:params) do
        { webhook: 'https://hook.example.com', username: 'username' }
      end

      before do
        project_integrations_map[integration_name].activate!
      end

      it 'accepts a username for update' do
        put api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user), params: params.merge(username: 'new_username')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['properties']['username']).to eq('new_username')
      end
    end

    describe 'Microsoft Teams integration' do
      let_it_be(:group) { create(:group) }
      let(:integration_name) { 'microsoft-teams' }
      let(:params) do
        {
          webhook: 'https://hook.example.com',
          branches_to_be_notified: 'default',
          notify_only_broken_pipelines: false
        }
      end

      before do
        create(:microsoft_teams_integration, group: group, project: nil)
        project.update!(namespace: group)
        project_integrations_map[integration_name.underscore].activate!
      end

      it 'accepts branches_to_be_notified for update' do
        put api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user),
          params: params.merge(branches_to_be_notified: 'all')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['properties']['branches_to_be_notified']).to eq('all')
      end

      it 'accepts notify_only_broken_pipelines for update' do
        put api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user),
          params: params.merge(notify_only_broken_pipelines: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['properties']['notify_only_broken_pipelines']).to eq(true)
      end

      it 'accepts `use_inherited_settings` for inheritance' do
        expect do
          put api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user),
            params: params.merge(use_inherited_settings: true)
        end.to change { project_integrations_map[integration_name.underscore].reload.inherit_from_id }.from(nil)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['inherited']).to eq(true)
      end
    end

    describe 'Hangouts Chat integration' do
      let(:integration_name) { 'hangouts-chat' }
      let(:params) do
        {
          webhook: 'https://hook.example.com',
          branches_to_be_notified: 'default'
        }
      end

      before do
        project_integrations_map[integration_name.underscore].activate!
      end

      it 'accepts branches_to_be_notified for update', :aggregate_failures do
        put api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user), params: params.merge(branches_to_be_notified: 'all')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['properties']['branches_to_be_notified']).to eq('all')
      end

      it 'only requires the webhook param' do
        put api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user), params: { webhook: 'https://hook.example.com' }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'Jira integration' do
      let(:integration_name) { 'jira' }
      let(:params) do
        { url: 'https://jira.example.com', username: 'username', password: 'password', jira_auth_type: 0 }
      end

      before do
        project_integrations_map[integration_name].properties = params
        project_integrations_map[integration_name].activate!
      end

      it 'returns the jira_issue_transition_id for get request' do
        get api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['properties']).to include('jira_issue_transition_id' => '56-1')
      end

      it 'returns the jira_issue_transition_id for put request' do
        put api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user), params: params.merge(jira_issue_transition_id: '1')

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['properties']['jira_issue_transition_id']).to eq('1')
      end
    end

    describe 'Pipelines Email Integration' do
      let(:integration_name) { 'pipelines-email' }

      context 'notify_only_broken_pipelines property was saved as a string' do
        before do
          project_integrations_map[integration_name.underscore].activate!
        end

        it 'returns boolean values for notify_only_broken_pipelines' do
          get api("/projects/#{project.id}/#{endpoint}/#{integration_name}", user)

          expect(json_response['properties']['notify_only_broken_pipelines']).to eq(true)
        end
      end
    end

    describe 'GitLab for Slack app integration' do
      before do
        stub_application_setting(slack_app_enabled: true)
        create(:gitlab_slack_application_integration, project: project)
      end

      describe "PUT /projects/:id/#{endpoint}/gitlab-slack-application" do
        context 'for integration creation' do
          before do
            project.gitlab_slack_application_integration.destroy!
          end

          it 'returns 422' do
            put api("/projects/#{project.id}/#{endpoint}/gitlab-slack-application", user)

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to eq('You cannot create the GitLab for Slack app integration from the API')
          end
        end

        context 'for integration update' do
          before do
            project.gitlab_slack_application_integration.update!(active: false)
          end

          it "does not enable the integration" do
            put api("/projects/#{project.id}/#{endpoint}/gitlab-slack-application", user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(project.gitlab_slack_application_integration.reload).to have_attributes(active: false)
          end
        end
      end

      describe "GET /projects/:id/#{endpoint}/gitlab-slack-application" do
        it "fetches the integration and returns the correct fields" do
          get api("/projects/#{project.id}/#{endpoint}/gitlab-slack-application", user)

          expect(response).to have_gitlab_http_status(:ok)
          assert_correct_response_fields(json_response['properties'].keys, project.gitlab_slack_application_integration)
        end
      end

      describe "DELETE /projects/:id/#{endpoint}/gitlab-slack-application" do
        it "disables the integration" do
          expect { delete api("/projects/#{project.id}/#{endpoint}/gitlab-slack-application", user) }
            .to change { project.gitlab_slack_application_integration.reload.activated? }.from(true).to(false)

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end

    describe 'GitLab for Jira Cloud app integration' do
      before do
        stub_application_setting(jira_connect_application_key: 'mock_key')
        create(:jira_cloud_app_integration, project: project)
      end

      describe "PUT /projects/:id/#{endpoint}/jira-cloud-app" do
        context 'for integration creation' do
          before do
            project.jira_cloud_app_integration.destroy!
          end

          it 'returns 422' do
            put api("/projects/#{project.id}/#{endpoint}/jira-cloud-app", user)

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
            expect(json_response['message']).to eq('You cannot create the GitLab for Jira Cloud app integration from the API')
          end
        end

        context 'for integration update' do
          before do
            project.jira_cloud_app_integration.update!(active: false)
          end

          it "does not enable the integration" do
            put api("/projects/#{project.id}/#{endpoint}/jira-cloud-app", user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(project.jira_cloud_app_integration.reload).to have_attributes(active: false)
          end
        end
      end

      describe "GET /projects/:id/#{endpoint}/jira-cloud-app" do
        it "fetches the integration and returns the correct fields" do
          get api("/projects/#{project.id}/#{endpoint}/jira-cloud-app", user)

          expect(response).to have_gitlab_http_status(:ok)
          assert_correct_response_fields(json_response['properties'].keys, project.jira_cloud_app_integration)
        end
      end

      describe "DELETE /projects/:id/#{endpoint}/jira-cloud-app" do
        it "does not disable the integration" do
          expect { delete api("/projects/#{project.id}/#{endpoint}/jira-cloud-app", user) }
            .not_to change { project.jira_cloud_app_integration.reload.activated? }.from(true)

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('You cannot disable the GitLab for Jira Cloud app integration from the API')
        end
      end
    end

    private

    def assert_correct_response_fields(response_keys, integration)
      assert_fields_match_integration(response_keys, integration)
      assert_secret_fields_filtered(response_keys, integration)
    end

    def assert_fields_match_integration(response_keys, integration)
      expect(response_keys).to match_array(integration.api_field_names)
    end

    def assert_secret_fields_filtered(response_keys, integration)
      expect(response_keys).not_to include(*integration.secret_fields) unless integration.secret_fields.empty?
    end
  end

  describe 'POST /slack/trigger' do
    before do
      stub_application_setting(slack_app_verification_token: 'token')
    end

    it 'returns status 200' do
      post api('/slack/trigger'), params: { token: 'token', text: 'help' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['response_type']).to eq("ephemeral")
    end

    it 'returns status 404 when token is invalid' do
      post api('/slack/trigger'), params: { token: 'invalid', text: 'foo' }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['response_type']).to be_blank
    end
  end
end
