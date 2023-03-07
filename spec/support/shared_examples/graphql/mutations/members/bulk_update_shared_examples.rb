# frozen_string_literal: true

RSpec.shared_examples 'members bulk update mutation' do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:member1) { create(member_type, source: source, user: user1) }
  let_it_be(:member2) { create(member_type, source: source, user: user2) }

  let(:extra_params) { { expires_at: 10.days.from_now } }
  let(:input_params) { input.merge(extra_params) }
  let(:mutation) { graphql_mutation(mutation_name, input_params) }
  let(:mutation_response) { graphql_mutation_response(mutation_name) }

  let(:input) do
    {
      source_id_key => source.to_global_id.to_s,
      'user_ids' => [user1.to_global_id.to_s, user2.to_global_id.to_s],
      'access_level' => 'GUEST'
    }
  end

  context 'when user is not logged-in' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user is not an owner' do
    before do
      source.add_developer(current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user is an owner' do
    before do
      source.add_owner(current_user)
    end

    shared_examples 'updates the user access role' do
      specify do
        post_graphql_mutation(mutation, current_user: current_user)

        new_access_levels = mutation_response[response_member_field].map do |member|
          member['accessLevel']['integerValue']
        end
        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to be_empty
        expect(new_access_levels).to all(be Gitlab::Access::GUEST)
      end
    end

    it_behaves_like 'updates the user access role'

    context 'when inherited members are passed' do
      let(:input) do
        {
          source_id_key => source.to_global_id.to_s,
          'user_ids' => [user1.to_global_id.to_s, user2.to_global_id.to_s, parent_group_member.user.to_global_id.to_s],
          'access_level' => 'GUEST'
        }
      end

      it 'does not update the members' do
        post_graphql_mutation(mutation, current_user: current_user)

        error = Mutations::Members::BulkUpdateBase::INVALID_MEMBERS_ERROR
        expect(json_response['errors'].first['message']).to include(error)
      end
    end

    context 'when members count is more than the allowed limit' do
      let(:max_members_update_limit) { 1 }

      before do
        stub_const('Mutations::Members::BulkUpdateBase::MAX_MEMBERS_UPDATE_LIMIT', max_members_update_limit)
      end

      it 'does not update the members' do
        post_graphql_mutation(mutation, current_user: current_user)

        error = Mutations::Members::BulkUpdateBase::MAX_MEMBERS_UPDATE_ERROR
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

        expect(mutation_response[response_member_field]).to be_nil
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
            members: [member1]
          }
          allow(instance).to receive(:execute).and_return(error_result)
        end
      end

      it 'will pass through the error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response[response_member_field].first['id']).to eq(member1.to_global_id.to_s)
        expect(mutation_response['errors']).to contain_exactly('Expires at cannot be a date in the past')
      end
    end
  end
end
