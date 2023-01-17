# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GroupMemberBulkUpdate', feature_category: :subgroups do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_member1) { create(:group_member, group: group, user: user1) }
  let_it_be(:group_member2) { create(:group_member, group: group, user: user2) }
  let_it_be(:mutation_name) { :group_member_bulk_update }

  let(:input) do
    {
      'group_id' => group.to_global_id.to_s,
      'user_ids' => [user1.to_global_id.to_s, user2.to_global_id.to_s],
      'access_level' => 'GUEST'
    }
  end

  let(:extra_params) { { expires_at: 10.days.from_now } }
  let(:input_params) { input.merge(extra_params) }
  let(:mutation) { graphql_mutation(mutation_name, input_params) }
  let(:mutation_response) { graphql_mutation_response(mutation_name) }

  context 'when user is not logged-in' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user is not an owner' do
    before do
      group.add_maintainer(current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user is an owner' do
    before do
      group.add_owner(current_user)
    end

    shared_examples 'updates the user access role' do
      specify do
        post_graphql_mutation(mutation, current_user: current_user)

        new_access_levels = mutation_response['groupMembers'].map { |member| member['accessLevel']['integerValue'] }
        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to be_empty
        expect(new_access_levels).to all(be Gitlab::Access::GUEST)
      end
    end

    it_behaves_like 'updates the user access role'

    context 'when inherited members are passed' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:subgroup_member) { create(:group_member, group: subgroup) }

      let(:input) do
        {
          'group_id' => group.to_global_id.to_s,
          'user_ids' => [user1.to_global_id.to_s, user2.to_global_id.to_s, subgroup_member.user.to_global_id.to_s],
          'access_level' => 'GUEST'
        }
      end

      it 'does not update the members' do
        post_graphql_mutation(mutation, current_user: current_user)

        error = Mutations::Members::Groups::BulkUpdate::INVALID_MEMBERS_ERROR
        expect(json_response['errors'].first['message']).to include(error)
      end
    end

    context 'when members count is more than the allowed limit' do
      let(:max_members_update_limit) { 1 }

      before do
        stub_const('Mutations::Members::Groups::BulkUpdate::MAX_MEMBERS_UPDATE_LIMIT', max_members_update_limit)
      end

      it 'does not update the members' do
        post_graphql_mutation(mutation, current_user: current_user)

        error = Mutations::Members::Groups::BulkUpdate::MAX_MEMBERS_UPDATE_ERROR
        expect(json_response['errors'].first['message']).to include(error)
      end
    end

    context 'when the update service raises access denied error' do
      before do
        allow_next_instance_of(Members::UpdateService) do |instance|
          allow(instance).to receive(:execute).and_raise(Gitlab::Access::AccessDeniedError)
        end
      end

      it 'does not update the members' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['groupMembers']).to be_nil
        expect(mutation_response['errors'])
          .to contain_exactly("Unable to update members, please check user permissions.")
      end
    end

    context 'when the update service returns an error message' do
      before do
        allow_next_instance_of(Members::UpdateService) do |instance|
          error_result = {
            message: 'Expires at cannot be a date in the past',
            status: :error,
            members: [group_member1]
          }
          allow(instance).to receive(:execute).and_return(error_result)
        end
      end

      it 'will pass through the error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['groupMembers'].first['id']).to eq(group_member1.to_global_id.to_s)
        expect(mutation_response['errors']).to contain_exactly('Expires at cannot be a date in the past')
      end
    end
  end
end
