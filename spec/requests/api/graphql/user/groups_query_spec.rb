# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting groups of a user', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:target_user) { create(:user, organizations: [current_organization]) }
  let_it_be(:group) { create(:group, organization: current_organization, maintainers: target_user) }

  let(:query) { graphql_query_for(:user, { username: target_user.username }, 'groups { nodes { id } }') }
  let(:path) { %i[user groups nodes] }

  before do
    current_organization.clear_memoization(:owner_user_ids)
    post_graphql(query, current_user: current_user)
  end

  context 'when the current user is an owner of the organization' do
    let(:current_user) { create(:user, owner_of: current_organization) }

    it_behaves_like 'a working graphql query'

    it 'returns the target user groups' do
      expect(graphql_data_at(*path)).to contain_exactly(
        a_graphql_entity_for(group)
      )
    end

    context 'when the target user belongs to a private group' do
      let_it_be(:private_group) do
        create(:group, :private, organization: current_organization, maintainers: target_user)
      end

      it 'returns the private group' do
        expect(graphql_data_at(*path)).to include(a_graphql_entity_for(private_group))
      end
    end

    context 'when the target user is not a member of the organization' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:outside_user) { create(:user, organizations: [other_organization]) }
      let_it_be(:outside_group) { create(:group, organization: other_organization, maintainers: outside_user) }

      let(:query) { graphql_query_for(:user, { username: outside_user.username }, 'groups { nodes { id } }') }

      it 'does not return groups outside the organization' do
        expect(graphql_data_at(*path)).to be_empty
      end
    end
  end

  context 'when the current user is only a member of the organization' do
    let(:current_user) { create(:user, organizations: [current_organization]) }

    it 'does not return the target user groups' do
      expect(graphql_data_at(:user, :groups)).to be_nil
    end
  end

  context 'when the current user is the target user' do
    let(:current_user) { target_user }

    it 'returns the target user groups' do
      expect(graphql_data_at(*path)).to contain_exactly(
        a_graphql_entity_for(group)
      )
    end

    context 'when soloOwned is true' do
      let_it_be(:solo_owned_group) { create(:group, organization: current_organization, owners: target_user) }
      let_it_be(:co_owned_group) do
        create(:group, organization: current_organization, owners: [target_user, create(:user)])
      end

      let(:query) do
        graphql_query_for(:user, { username: target_user.username }, 'groups(soloOwned: true) { nodes { id } }')
      end

      it 'returns only groups solely owned by the user within the current organization' do
        expect(graphql_data_at(*path)).to contain_exactly(
          a_graphql_entity_for(solo_owned_group)
        )
      end
    end
  end

  context 'when the current user is an unrelated user with no special role' do
    let(:current_user) { create(:user) }

    it 'does not return the target user groups' do
      expect(graphql_data_at(:user, :groups)).to be_nil
    end

    it 'does not raise a top-level error' do
      expect(graphql_errors).to be_nil
    end
  end
end
