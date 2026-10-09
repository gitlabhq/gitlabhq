# frozen_string_literal: true

require 'spec_helper'

# Use without_current_organization metadata to ensure current organization isn't stubbed.
# This enables testing Current.organization resolution from path params.
RSpec.describe Admin::Organizations::IntegrationsController, :without_current_organization,
  feature_category: :integrations do
  include JiraIntegrationHelpers

  let_it_be(:organization) { create(:organization) }
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:user, :organization_owner, organization: organization) }
  let_it_be(:regular_user) { create(:user) }

  describe 'GET /o/:organization_path/admin/settings/integrations' do
    subject(:request) { get organization_admin_settings_integrations_path(organization) }

    let(:other_organization_request) { get organization_admin_settings_integrations_path(other_organization) }

    it_behaves_like 'an organization admin area request'

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders the integrations list for the organization', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('js-integrations-list')
        expect(response.body).to include(edit_organization_admin_settings_integration_path(organization, 'jira'))
      end

      it 'renders the help link with safe attributes' do
        request

        expect(response.body).to include('rel="noopener noreferrer"')
        expect(response.body).to include('integration management</a>')
      end

      it 'does not list instance-only integrations' do
        request

        expect(response.body).not_to include('Beyond Identity')
        expect(response.body).not_to include('beyond_identity')
      end

      it 'does not use the instance admin routes' do
        request

        expect(response.body).not_to include('/admin/application_settings/integrations')
      end

      it 'lists the integrations as configured only for the organization that has them', :aggregate_failures do
        own = create(:jira_integration, :instance, organization: organization)
        other = create(:jira_integration, :instance, organization: other_organization)

        request

        expect(response.body).to include("&quot;id&quot;:#{own.id}")
        expect(response.body).not_to include("&quot;id&quot;:#{other.id}")
      end

      context 'when the user lacks the update_integration ability' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?)
            .with(organization_owner, :update_integration, organization).and_return(false)
        end

        it 'denies access' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when on GitLab.com', :saas do
        it 'still renders the page' do
          request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end

  describe 'GET /o/:organization_path/admin/settings/integrations/:id/edit' do
    subject(:request) { get edit_organization_admin_settings_integration_path(organization, 'jira') }

    let(:other_organization_request) do
      get edit_organization_admin_settings_integration_path(other_organization, 'jira')
    end

    it_behaves_like 'an organization admin area request'

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders org-scoped form paths', :aggregate_failures do
        request

        expect(response.body).to include(organization_admin_settings_integration_path(organization, 'jira'))
        expect(response.body).not_to include('/admin/application_settings/integrations')
      end

      it 'does not load another organization integration' do
        other = create(:jira_integration, :instance, organization: other_organization, url: 'https://other.example.com')

        request

        expect(response.body).not_to include('https://other.example.com')
        expect(response.body).not_to include("&quot;id&quot;:#{other.id}")
      end

      it 'returns 404 for an unknown integration' do
        get edit_organization_admin_settings_integration_path(organization, 'does_not_exist')

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when the user lacks the update_integration ability' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?)
            .with(organization_owner, :update_integration, organization).and_return(false)
        end

        it 'denies access' do
          request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'instance-only integrations' do
    let(:name) { 'beyond_identity' }

    before do
      sign_in(organization_owner)
    end

    it 'returns 404 for edit' do
      get edit_organization_admin_settings_integration_path(organization, name)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for overrides' do
      get overrides_organization_admin_settings_integration_path(organization, name)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for test' do
      put test_organization_admin_settings_integration_path(organization, name), params: { service: {} }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for reset' do
      post reset_organization_admin_settings_integration_path(organization, name)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 for update and does not create an integration', :aggregate_failures do
      expect do
        put organization_admin_settings_integration_path(organization, name),
          params: { service: { active: true } }
      end.not_to change { Integration.count }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'PUT /o/:organization_path/admin/settings/integrations/:id' do
    subject(:request) do
      put organization_admin_settings_integration_path(organization, 'jira'), params: { service: params }
    end

    let(:params) { { url: 'https://jira.gitlab-example.com', password: 'password' } }

    before do
      stub_jira_integration_test
      allow(PropagateIntegrationWorker).to receive(:perform_async)
    end

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'creates the integration for the organization and redirects to the org edit page', :aggregate_failures do
        expect { request }.to change { Integrations::Jira.where(instance: true, organization: organization).count }
          .by(1)

        expect(response).to redirect_to(edit_organization_admin_settings_integration_path(organization, 'jira'))
        expect(Integrations::Jira.find_by(instance: true, organization: organization)).to have_attributes(params)
      end

      it 'propagates the integration' do
        request

        expect(PropagateIntegrationWorker).to have_received(:perform_async)
          .with(Integrations::Jira.find_by(instance: true, organization: organization).id)
      end

      it 'does not modify an integration of another organization', :aggregate_failures do
        other = create(:jira_integration, :instance, organization: other_organization, url: 'https://other.example.com')

        request

        expect(other.reload.url).to eq('https://other.example.com')
        expect(Integrations::Jira.where(instance: true).count).to eq(2)
      end

      it 'updates an existing integration of the organization' do
        existing = create(:jira_integration, :instance, organization: organization)

        request

        expect(existing.reload).to have_attributes(params)
      end

      context 'when targeting another organization path' do
        let_it_be(:other) { create(:jira_integration, :instance, organization: other_organization) }

        it 'denies access and leaves the other organization integration untouched', :aggregate_failures do
          put organization_admin_settings_integration_path(other_organization, 'jira'),
            params: { service: { url: 'https://evil.example.com', password: 'password' } }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(other.reload.url).not_to eq('https://evil.example.com')
          expect(PropagateIntegrationWorker).not_to have_received(:perform_async)
        end
      end

      context 'with invalid params' do
        let(:params) { { url: 'invalid', password: 'password' } }

        let_it_be(:existing) { create(:jira_integration, :instance, organization: organization) }

        it 'renders the edit form without saving or propagating', :aggregate_failures do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(existing.reload.url).not_to eq('invalid')
          expect(PropagateIntegrationWorker).not_to have_received(:perform_async)
        end
      end
    end

    context 'when user is a regular user' do
      before do
        sign_in(regular_user)
      end

      it 'denies access and does not create an integration', :aggregate_failures do
        expect { request }.not_to change { Integration.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /o/:organization_path/admin/settings/integrations/:id/overrides' do
    subject(:request) { get overrides_organization_admin_settings_integration_path(organization, 'jira') }

    let(:other_organization_request) do
      get overrides_organization_admin_settings_integration_path(other_organization, 'jira')
    end

    it_behaves_like 'an organization admin area request'

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders org-scoped overrides paths' do
        request

        expect(response.body).to include(
          overrides_organization_admin_settings_integration_path(organization, 'jira', format: :json)
        )
      end

      context 'with JSON format' do
        subject(:request) do
          get overrides_organization_admin_settings_integration_path(organization, 'jira', format: :json)
        end

        let_it_be(:project) { create(:project, organization: organization) }
        let_it_be(:other_project) { create(:project, organization: other_organization) }

        before_all do
          create(:jira_integration, project: project, inherit_from_id: nil)
          create(:jira_integration, project: other_project, inherit_from_id: nil)
        end

        it 'only includes projects of the organization', :aggregate_failures do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.pluck('id')).to contain_exactly(project.id)
        end
      end
    end
  end

  describe 'PUT /o/:organization_path/admin/settings/integrations/:id/test' do
    subject(:request) do
      put test_organization_admin_settings_integration_path(organization, 'jira'), params: { service: {} }
    end

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'returns not found for an integration that is not testable at this level' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is a regular user' do
      before do
        sign_in(regular_user)
      end

      it 'denies access' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /o/:organization_path/admin/settings/integrations/:id/reset' do
    subject(:request) { post reset_organization_admin_settings_integration_path(organization, integration.to_param) }

    let_it_be(:integration) { create(:jira_integration, :instance, organization: organization) }

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'destroys the organization integration', :aggregate_failures do
        expect { request }.to change { Integration.exists?(integration.id) }.from(true).to(false)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does not touch an integration of another organization' do
        other = create(:jira_integration, :instance, organization: other_organization)

        request

        expect(Integration.exists?(other.id)).to be(true)
      end
    end

    context 'when targeting another organization path' do
      let_it_be(:other) { create(:jira_integration, :instance, organization: other_organization) }

      before do
        sign_in(organization_owner)
      end

      it 'denies access and keeps the other organization integration', :aggregate_failures do
        post reset_organization_admin_settings_integration_path(other_organization, other.to_param)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(Integration.exists?(other.id)).to be(true)
      end
    end

    context 'when user is a regular user' do
      before do
        sign_in(regular_user)
      end

      it 'denies access and keeps the integration', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:not_found)
        expect(Integration.exists?(integration.id)).to be(true)
      end
    end
  end
end
