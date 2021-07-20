# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Services do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:project, reload: true) do
    create(:project, creator_id: user.id, namespace: user.namespace)
  end

  describe "GET /projects/:id/services" do
    it 'returns authentication error when unauthenticated' do
      get api("/projects/#{project.id}/services")

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it "returns error when authenticated but user is not a project owner" do
      project.add_developer(user2)
      get api("/projects/#{project.id}/services", user2)

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'with integrations' do
      let!(:active_integration) { create(:emails_on_push_integration, project: project, active: true) }
      let!(:integration) { create(:custom_issue_tracker_integration, project: project, active: false) }

      it "returns a list of all active integrations" do
        get api("/projects/#{project.id}/services", user)

        aggregate_failures 'expect successful response with all active integrations' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an Array
          expect(json_response.count).to eq(1)
          expect(json_response.first['slug']).to eq('emails-on-push')
          expect(response).to match_response_schema('public_api/v4/services')
        end
      end
    end
  end

  Integration.available_integration_names.each do |integration|
    describe "PUT /projects/:id/services/#{integration.dasherize}" do
      include_context integration

      it "updates #{integration} settings" do
        put api("/projects/#{project.id}/services/#{dashed_integration}", user), params: integration_attrs

        expect(response).to have_gitlab_http_status(:ok)

        current_integration = project.integrations.first
        events = current_integration.event_names.empty? ? ["foo"].freeze : current_integration.event_names
        query_strings = []
        events.each do |event|
          query_strings << "#{event}=#{!current_integration[event]}"
        end
        query_strings = query_strings.join('&')

        put api("/projects/#{project.id}/services/#{dashed_integration}?#{query_strings}", user), params: integration_attrs

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['slug']).to eq(dashed_integration)
        events.each do |event|
          next if event == "foo"

          expect(project.integrations.first[event]).not_to eq(current_integration[event]),
            "expected #{!current_integration[event]} for event #{event} for service #{current_integration.title}, got #{current_integration[event]}"
        end
      end

      it "returns if required fields missing" do
        required_attributes = integration_attrs_list.select do |attr|
          integration_klass.validators_on(attr).any? do |v|
            v.instance_of?(ActiveRecord::Validations::PresenceValidator) &&
            # exclude presence validators with conditional since those are not really required
            ![:if, :unless].any? { |cond| v.options.include?(cond) }
          end
        end

        if required_attributes.empty?
          expected_code = :ok
        else
          integration_attrs.delete(required_attributes.sample)
          expected_code = :bad_request
        end

        put api("/projects/#{project.id}/services/#{dashed_integration}", user), params: integration_attrs

        expect(response).to have_gitlab_http_status(expected_code)
      end
    end

    describe "DELETE /projects/:id/services/#{integration.dasherize}" do
      include_context integration

      before do
        initialize_integration(integration)
      end

      it "deletes #{integration}" do
        delete api("/projects/#{project.id}/services/#{dashed_integration}", user)

        expect(response).to have_gitlab_http_status(:no_content)
        project.send(integration_method).reload
        expect(project.send(integration_method).activated?).to be_falsey
      end
    end

    describe "GET /projects/:id/services/#{integration.dasherize}" do
      include_context integration

      let!(:initialized_integration) { initialize_integration(integration, active: true) }

      let_it_be(:project2) do
        create(:project, creator_id: user.id, namespace: user.namespace)
      end

      def deactive_integration!
        return initialized_integration.update!(active: false) unless initialized_integration.is_a?(::Integrations::Prometheus)

        # Integrations::Prometheus sets `#active` itself within a `before_save`:
        initialized_integration.manual_configuration = false
        initialized_integration.save!
      end

      it 'returns authentication error when unauthenticated' do
        get api("/projects/#{project.id}/services/#{dashed_integration}")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it "returns all properties of active service #{integration}" do
        get api("/projects/#{project.id}/services/#{dashed_integration}", user)

        expect(initialized_integration).to be_active
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['properties'].keys).to match_array(integration_instance.api_field_names)
      end

      it "returns all properties of inactive integration #{integration}" do
        deactive_integration!

        get api("/projects/#{project.id}/services/#{dashed_integration}", user)

        expect(initialized_integration).not_to be_active
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['properties'].keys).to match_array(integration_instance.api_field_names)
      end

      it "returns not found if integration does not exist" do
        get api("/projects/#{project2.id}/services/#{dashed_integration}", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Service Not Found')
      end

      it "returns not found if service exists but is in `Project#disabled_integrations`" do
        expect_next_found_instance_of(Project) do |project|
          expect(project).to receive(:disabled_integrations).at_least(:once).and_return([integration])
        end

        get api("/projects/#{project.id}/services/#{dashed_integration}", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Service Not Found')
      end

      it "returns error when authenticated but not a project owner" do
        project.add_developer(user2)
        get api("/projects/#{project.id}/services/#{dashed_integration}", user2)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /projects/:id/services/:slug/trigger' do
    describe 'Mattermost integration' do
      let(:integration_name) { 'mattermost_slash_commands' }

      context 'when no integration is available' do
        it 'returns a not found message' do
          post api("/projects/#{project.id}/services/idonotexist/trigger")

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response["error"]).to eq("404 Not Found")
        end
      end

      context 'when the integration exists' do
        let(:params) { { token: 'token' } }

        context 'when the integration is not active' do
          before do
            project.create_mattermost_slash_commands_integration(
              active: false,
              properties: params
            )
          end

          it 'when the integration is inactive' do
            post api("/projects/#{project.id}/services/#{integration_name}/trigger"), params: params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when the integration is active' do
          before do
            project.create_mattermost_slash_commands_integration(
              active: true,
              properties: params
            )
          end

          it 'returns status 200' do
            post api("/projects/#{project.id}/services/#{integration_name}/trigger"), params: params

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when the project can not be found' do
          it 'returns a generic 404' do
            post api("/projects/404/services/#{integration_name}/trigger"), params: params

            expect(response).to have_gitlab_http_status(:not_found)
            expect(json_response["message"]).to eq("404 Service Not Found")
          end
        end
      end
    end

    describe 'Slack Integration' do
      let(:integration_name) { 'slack_slash_commands' }

      before do
        project.create_slack_slash_commands_integration(
          active: true,
          properties: { token: 'token' }
        )
      end

      it 'returns status 200' do
        post api("/projects/#{project.id}/services/#{integration_name}/trigger"), params: { token: 'token', text: 'help' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['response_type']).to eq("ephemeral")
      end
    end
  end

  describe 'Mattermost integration' do
    let(:integration_name) { 'mattermost' }
    let(:params) do
      { webhook: 'https://hook.example.com', username: 'username' }
    end

    before do
      project.create_mattermost_integration(
        active: true,
        properties: params
      )
    end

    it 'accepts a username for update' do
      put api("/projects/#{project.id}/services/#{integration_name}", user), params: params.merge(username: 'new_username')

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['properties']['username']).to eq('new_username')
    end
  end

  describe 'Microsoft Teams integration' do
    let(:integration_name) { 'microsoft-teams' }
    let(:params) do
      {
        webhook: 'https://hook.example.com',
        branches_to_be_notified: 'default',
        notify_only_broken_pipelines: false
      }
    end

    before do
      project.create_microsoft_teams_integration(
        active: true,
        properties: params
      )
    end

    it 'accepts branches_to_be_notified for update' do
      put api("/projects/#{project.id}/services/#{integration_name}", user),
          params: params.merge(branches_to_be_notified: 'all')

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['properties']['branches_to_be_notified']).to eq('all')
    end

    it 'accepts notify_only_broken_pipelines for update' do
      put api("/projects/#{project.id}/services/#{integration_name}", user),
          params: params.merge(notify_only_broken_pipelines: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['properties']['notify_only_broken_pipelines']).to eq(true)
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
      project.create_hangouts_chat_integration(
        active: true,
        properties: params
      )
    end

    it 'accepts branches_to_be_notified for update', :aggregate_failures do
      put api("/projects/#{project.id}/services/#{integration_name}", user), params: params.merge(branches_to_be_notified: 'all')

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['properties']['branches_to_be_notified']).to eq('all')
    end

    it 'only requires the webhook param' do
      put api("/projects/#{project.id}/services/#{integration_name}", user), params: { webhook: 'https://hook.example.com' }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'Pipelines Email Integration' do
    let(:integration_name) { 'pipelines-email' }

    context 'notify_only_broken_pipelines property was saved as a string' do
      before do
        project.create_pipelines_email_integration(
          active: false,
          properties: {
            "notify_only_broken_pipelines": "true",
            "branches_to_be_notified": "default"
          }
        )
      end

      it 'returns boolean values for notify_only_broken_pipelines' do
        get api("/projects/#{project.id}/services/#{integration_name}", user)

        expect(json_response['properties']['notify_only_broken_pipelines']).to eq(true)
      end
    end
  end
end
