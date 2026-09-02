# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Organizations::UsersController, feature_category: :organization do
  let_it_be(:organization) { create(:common_organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:user, :organization_owner) }
  let_it_be(:regular_user) { create(:user) }
  let_it_be(:user) { create(:user) }

  describe 'GET #index' do
    subject(:request) { get organization_admin_users_path(organization) }

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders the index' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'scopes the listed users to members of the organization' do
        non_member = create(:user, organization: create(:organization))

        request

        expect(response.body).to include(user.username)
        expect(response.body).not_to include(non_member.username)
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
        let_it_be(:other_organization) { create(:organization) }

        it 'denies access' do
          get organization_admin_users_path(other_organization)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is an instance admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'renders the index' do
        request

        expect(response).to have_gitlab_http_status(:ok)
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

        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end

  describe 'GET #show' do
    subject(:request) { get organization_admin_user_path(organization, user) }

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders the user' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when user is an instance admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'renders the impersonate button disabled' do
        request

        expect(response.body).to match(
          /<[^>]*data-testid="impersonate-user-link"[^>]*\bdisabled\b/
        )
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

  describe 'unavailable actions' do
    it 'only defines index and show' do
      %i[
        new create edit update destroy projects keys approve reject activate deactivate
        block unblock ban unban unlock trust untrust confirm disable_two_factor
        impersonate remove_email
      ].each do |action|
        expect(described_class.new).not_to respond_to(action)
      end
    end
  end
end
