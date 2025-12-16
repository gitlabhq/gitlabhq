# frozen_string_literal: true

require 'spec_helper'

require_relative '../concerns/membership_actions_shared_examples'

RSpec.describe Projects::ProjectMembersController, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:membershipable) { create(:project, :public, namespace: create(:group, :public), creator: user) }

  let(:membershipable_path) { project_path(membershipable) }

  describe 'GET /*namespace_id/:project_id/-/project_members/request_access' do
    subject(:request) do
      get request_access_namespace_project_project_members_path(
        namespace_id: membershipable.namespace,
        project_id: membershipable
      )
    end

    it_behaves_like 'request_accessable'
  end

  describe 'GET /*namespace_id/:project_id/-/project_members/invite_search.json' do
    subject(:request) do
      get invite_search_namespace_project_project_members_path(
        namespace_id: membershipable.namespace,
        project_id: membershipable,
        params: params,
        format: :json
      )
    end

    let(:params) { {} }

    let_it_be(:regular_user) { create(:user) }
    let_it_be(:admin_user) { create(:user, :admin) }
    let_it_be(:banned_user) { create(:user, :banned) }
    let_it_be(:blocked_user) { create(:user, :blocked) }
    let_it_be(:ldap_blocked_user) { create(:user, :ldap_blocked) }
    let_it_be(:external_user) { create(:user, :external) }
    let_it_be(:unconfirmed_user) { create(:user, confirmed_at: nil) }
    let_it_be(:omniauth_user) { create(:omniauth_user) }
    let_it_be(:internal_user) { Users::Internal.alert_bot }
    let_it_be(:project_bot_user) { create(:user, :project_bot) }
    let_it_be(:service_account_user) { create(:user, :service_account) }
    let_it_be(:other_organization) { create(:organization) }
    let_it_be(:other_organization_user) { create(:user, organization: other_organization) }

    let(:searchable_users) do
      [
        user,
        regular_user,
        admin_user,
        external_user,
        unconfirmed_user,
        omniauth_user,
        service_account_user
      ]
    end

    before do
      sign_in(user)
    end

    context 'when user has permission to manage project members' do
      before_all do
        membershipable.add_maintainer(user)
      end

      it 'returns searchable users' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to match_array(searchable_users.map(&:id))
      end

      context 'for search param' do
        let(:params) { { search: search } }

        context 'with empty string' do
          let(:search) { '' }

          it 'returns searchable users' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to match_array(searchable_users.map(&:id))
          end
        end

        context "with a user's name" do
          let(:search) { regular_user.name }

          it 'returns users that match the name' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to contain_exactly(regular_user.id)
          end
        end
      end
    end

    context 'when user does not have permission to manage project members' do
      before_all do
        membershipable.add_developer(user)
      end

      it 'returns 404 not_found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
