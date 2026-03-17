# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Organizations::DashboardController, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:user, :organization_owner, organization: organization) }
  let_it_be(:regular_user) { create(:user) }

  shared_examples 'the feature flag is disabled' do
    before do
      stub_feature_flags(org_admin_area: false)
    end

    it 'denies access' do
      get organization_admin_organization_dashboard_path(organization)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  # Use without_current_organization metadata to ensure current organization isn't stubbed.
  # This enables testing Current.organization resolution from path params.
  describe 'GET /o/:organization_path/admin/organization', :without_current_organization do
    context 'when user is an instance admin' do
      before do
        sign_in(admin)
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'renders the organization admin dashboard' do
          get organization_admin_organization_dashboard_path(organization)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include(_('Organization Administration'))
        end

        it_behaves_like 'the feature flag is disabled'
      end

      context 'when admin mode is not enabled' do
        it 'redirects to admin mode login' do
          get organization_admin_organization_dashboard_path(organization)

          expect(response).to redirect_to(new_admin_session_path)
        end
      end
    end

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders the organization admin dashboard' do
        get organization_admin_organization_dashboard_path(organization)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include(_('Organization Administration'))
      end

      context 'when accessing another organization admin path' do
        let_it_be(:other_organization) { create(:organization) }

        it 'denies access' do
          get organization_admin_organization_dashboard_path(other_organization)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when X-GitLab-Organization-ID header is provided' do
        it 'uses organization from path, not header' do
          header_organization = create(:organization)

          get organization_admin_organization_dashboard_path(organization),
            headers: { 'X-GitLab-Organization-ID' => header_organization.id.to_s }

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'renders the header organization' do
          get admin_organization_dashboard_path, headers: { 'X-GitLab-Organization-ID' => organization.id.to_s }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      it_behaves_like 'the feature flag is disabled'
    end

    context 'when user is a regular user' do
      before do
        sign_in(regular_user)
      end

      it 'denies access' do
        get organization_admin_organization_dashboard_path(organization)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to login' do
        get organization_admin_organization_dashboard_path(organization)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
