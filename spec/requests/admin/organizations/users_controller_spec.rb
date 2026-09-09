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

      it 'renders the invite organization user button' do
        request

        expect(response.body).to include('js-admin-add-organization-users')
      end

      context 'when the user cannot create an organization user' do
        before do
          allow(organization_owner).to receive(:can?).and_call_original
          allow(organization_owner).to receive(:can?)
            .with(:create_organization_user,
              an_object_having_attributes(organization: organization))
            .and_return(false)
        end

        it 'does not render the invite organization user button' do
          request

          expect(response.body).not_to include('js-admin-add-organization-users')
        end
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

  describe 'GET #edit' do
    subject(:request) { get edit_organization_admin_user_path(organization, user) }

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders the edit form' do
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
  end

  describe 'PATCH #update' do
    let_it_be(:organization_user) { organization.organization_users.find_by(user: user) }
    let(:params) do
      {
        user: {
          organization_users_attributes: [
            { id: organization_user.id, organization_id: organization.id, access_level: 'owner' }
          ]
        }
      }
    end

    subject(:request) { patch organization_admin_user_path(organization, user), params: params }

    context 'when user is an instance admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'updates the organization access level and redirects to the user show page' do
        request

        expect(response).to redirect_to(organization_admin_user_path(organization, user))
        expect(organization_user.reload.access_level).to eq('owner')
      end
    end

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'updates the organization access level and redirects to the user show page' do
        request

        expect(response).to redirect_to(organization_admin_user_path(organization, user))
        expect(organization_user.reload.access_level).to eq('owner')
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
    it 'only defines index, show, edit and update' do
      %i[
        new create destroy projects keys approve reject activate deactivate
        block unblock ban unban unlock trust untrust confirm disable_two_factor
        impersonate remove_email
      ].each do |action|
        expect(described_class.new).not_to respond_to(action)
      end
    end
  end
end
