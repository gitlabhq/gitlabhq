# frozen_string_literal: true

# Shared examples for the authorization matrix enforced by
# Admin::Organizations::ApplicationController#authorize_access_organization_admin_area!.
#
# This is the single, thorough place that exercises organization admin area
# access control. Each organization admin controller spec runs it as a smoke
# test and then adds its own controller-specific assertions.
#
# Requires the caller to define:
# - `request`: makes the request under test, against `organization`
# - `other_organization_request`: the same action against a different organization
# - `organization`: the request's organization
# - `organization_owner`: a user who owns `organization`
# - `admin`: an instance admin
# - `regular_user`: a user with no access to the organization admin area
RSpec.shared_examples 'an organization admin area request' do
  context 'when user is an instance admin' do
    before do
      sign_in(admin)
    end

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'renders the page' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'resolves the organization from the path before authorizing against it' do
        allow(Ability).to receive(:allowed?).and_call_original
        expect(Ability).to receive(:allowed?)
          .with(admin, :access_organization_admin_area, organization)
          .and_call_original
          .at_least(:once)

        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when admin mode is not enabled' do
      it 'redirects to admin mode login' do
        request

        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  context 'when user is an organization owner' do
    before do
      sign_in(organization_owner)
    end

    it 'renders the page' do
      request

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when the org_admin_area flag is disabled' do
      before do
        stub_organization_release(org_admin_area: false)
      end

      it 'denies access' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when accessing another organization admin path' do
      it 'denies access' do
        other_organization_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
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

  context 'when user is not authenticated' do
    it 'redirects to sign in' do
      request

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
