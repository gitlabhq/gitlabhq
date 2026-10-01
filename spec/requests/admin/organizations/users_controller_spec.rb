# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Organizations::UsersController, feature_category: :organization do
  let_it_be(:organization) { create(:common_organization) }
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:user, :organization_owner) }
  let_it_be(:regular_user) { create(:user) }
  let_it_be(:user) { create(:user) }

  describe 'GET #index' do
    subject(:request) { get organization_admin_users_path(organization) }

    let(:other_organization_request) { get organization_admin_users_path(other_organization) }

    it_behaves_like 'an organization admin area request'

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'scopes the listed users to members of the organization' do
        non_member = create(:user, organization: create(:organization), username: 'non-member-scope-test')

        request

        expect(response.body).to include(user.username)
        expect(response.body).not_to include(non_member.username)
      end

      it 'renders the invite organization user button' do
        request

        expect(response.body).to include('js-admin-add-organization-users')
      end

      it 'renders the Cohorts tab scoped to the organization' do
        request

        expect(response.body).to include(organization_admin_cohorts_path(organization))
      end

      it 'renders the search bar without filter tokens' do
        request

        expect(response.body).to include('data-show-filter-tokens="false"')
      end

      it 'ignores the filter param' do
        blocked_member = create(:user, :blocked, organization: organization, username: 'blocked-member')

        get organization_admin_users_path(organization), params: { filter: 'blocked' }

        expect(response.body).to include(user.username)
        expect(response.body).to include(blocked_member.username)
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
  end

  describe 'GET #show' do
    subject(:request) { get organization_admin_user_path(organization, user) }

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'renders the organization user show page' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to have_link('Account')
      end

      context 'when viewing a user belonging to another organization' do
        let_it_be(:non_member) { create(:user, organization: create(:organization)) }

        it 'denies access' do
          get organization_admin_user_path(organization, non_member)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is an instance admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'renders the show page without instance-only actions' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).not_to match(/data-testid="impersonate-user-link"/)
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

  describe 'GET #invite_search' do
    let_it_be(:existing_member) do
      create(:user, organization: organization, name: 'Zed Member', username: 'zed-member')
    end

    let_it_be(:invitable_user) do
      create(:user, organization: other_organization, name: 'Zed Candidate', username: 'zed-candidate')
    end

    subject(:request) do
      get invite_search_organization_admin_users_path(organization, format: :json), params: { search: 'Zed' }
    end

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'returns matching users who are not already members', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(invitable_user.id)
      end

      it 'serializes the fields the invite modal renders' do
        request

        expect(json_response.first.keys).to include('id', 'name', 'username', 'avatar_url')
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :autocomplete_users, use_second_scope: false do
        let(:current_user) { organization_owner }

        def request
          get invite_search_organization_admin_users_path(organization, format: :json), params: { search: 'Zed' }
        end
      end

      context 'when more users match than the page size' do
        let_it_be(:more_invitable_users) { create_list(:user, 2, organization: other_organization) }

        before do
          stub_const("#{described_class}::INVITE_SEARCH_PER_PAGE", 2)
        end

        it 'caps the number of returned users regardless of the requested per_page' do
          get invite_search_organization_admin_users_path(organization, format: :json), params: { per_page: 100 }

          expect(json_response.size).to eq(2)
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

      context 'when searching another organization admin path' do
        it 'denies access' do
          get invite_search_organization_admin_users_path(other_organization, format: :json)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is an instance admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'returns matching users who are not already members', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to contain_exactly(invitable_user.id)
      end

      it 'excludes users in forbidden states even for admins', :aggregate_failures do
        banned_user = create(:user, :banned, organization: other_organization, name: 'Zed Banned')
        blocked_user = create(:user, :blocked, organization: other_organization, name: 'Zed Blocked')
        ldap_blocked_user = create(:user, :ldap_blocked, organization: other_organization, name: 'Zed Ldap')

        request

        returned_ids = json_response.pluck('id')
        expect(returned_ids).not_to include(banned_user.id)
        expect(returned_ids).not_to include(blocked_user.id)
        expect(returned_ids).not_to include(ldap_blocked_user.id)
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
      it 'denies access' do
        request

        expect(response).to have_gitlab_http_status(:unauthorized)
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
