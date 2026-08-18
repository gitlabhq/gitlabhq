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

  describe 'GET /*namespace_id/:project_id/-/project_members.json (direct members)' do
    let_it_be(:parent_group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, namespace: parent_group) }
    let_it_be(:direct_member) { create(:project_member, :developer, source: project).user }
    let_it_be(:inherited_member) { create(:group_member, :developer, source: parent_group).user }

    let(:params) { {} }
    let(:member_ids) { json_response['members'].map { |member| member['id'] } }

    before_all do
      project.add_maintainer(user)
    end

    before do
      sign_in(user)
    end

    subject(:make_json_request) do
      get namespace_project_project_members_path(parent_group, project, format: :json), params: params
    end

    it 'returns only direct project members, excluding inherited members' do
      make_json_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(member_ids).to include(project.member(user).id, project.member(direct_member).id)
      expect(json_response['members'].map { |member| member['source']['id'] }).to all(eq(project.id))
    end

    it 'returns a complete direct members list independent of inherited membership volume' do
      # Add many inherited members that would sort ahead of direct members on the
      # combined members list, which previously pushed direct members past page 1.
      create_list(:group_member, 3, :developer, source: parent_group)

      make_json_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(member_ids).to include(project.member(direct_member).id)
    end

    context 'with a direct-members search' do
      let(:params) { { search_direct_members: direct_member.name } }

      it 'filters the direct members' do
        make_json_request

        expect(member_ids).to contain_exactly(project.member(direct_member).id)
      end
    end
  end

  describe 'DELETE /*namespace_id/:project_id/-/project_members/leave' do
    before do
      sign_in(user)
    end

    context 'when user is a direct member' do
      before_all do
        membershipable.add_developer(user)
      end

      it 'removes the member' do
        expect do
          delete leave_namespace_project_project_members_path(
            namespace_id: membershipable.namespace,
            project_id: membershipable
          )
        end.to change { membershipable.members.count }.by(-1)
      end
    end

    context 'when user is a requester' do
      before do
        membershipable.request_access(user)
      end

      it 'removes the access request' do
        expect do
          delete leave_namespace_project_project_members_path(
            namespace_id: membershipable.namespace,
            project_id: membershipable
          )
        end.to change { membershipable.requesters.count }.by(-1)
      end
    end
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
    let_it_be(:internal_user) { Users::Internal.in_organization(membershipable.organization).alert_bot }
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
