# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.frecentGroups', feature_category: :navigation do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_organization) { create(:organization) }

  # GraphQL request specs run with the common organization as the current one,
  # which is also what the group factory falls back to.
  let_it_be(:group_in_current_organization) { create(:group, :public) }
  let_it_be(:group_in_other_organization) { create(:group, :public, organization: other_organization) }

  let(:args) { {} }
  let(:query) { graphql_query_for(:frecent_groups, args, 'id') }

  subject(:frecent_groups) { graphql_data_at(:frecent_groups) }

  before_all do
    [group_in_current_organization, group_in_other_organization].each do |group|
      ::Users::GroupVisit.create!(entity_id: group.id, user_id: user.id, visited_at: 1.day.ago)
    end
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when authenticated' do
    let(:current_user) { user }

    it 'returns the frecently visited groups from every organization' do
      expect(frecent_groups).to contain_exactly(
        a_graphql_entity_for(group_in_current_organization),
        a_graphql_entity_for(group_in_other_organization)
      )
    end

    context 'with scopeToOrganization enabled' do
      let(:args) { { scope_to_organization: true } }

      it 'returns only the groups belonging to the current organization' do
        expect(frecent_groups).to contain_exactly(a_graphql_entity_for(group_in_current_organization))
      end
    end

    context 'with scopeToOrganization enabled but no current organization' do
      let(:args) { { scope_to_organization: true } }

      let(:current_organization) { nil }

      it 'returns an error instead of groups from every organization' do
        expect(frecent_groups).to be_nil
        expect(graphql_errors).to include(
          a_hash_including(
            'message' => ::Resolvers::Users::FrecentGroupsResolver::ORGANIZATION_UNAVAILABLE_ERROR
          )
        )
      end
    end

    context 'with scopeToOrganization disabled' do
      let(:args) { { scope_to_organization: false } }

      it 'returns the frecently visited groups from every organization' do
        expect(frecent_groups).to contain_exactly(
          a_graphql_entity_for(group_in_current_organization),
          a_graphql_entity_for(group_in_other_organization)
        )
      end
    end
  end

  context 'when unauthenticated' do
    let(:current_user) { nil }

    it 'returns no groups' do
      expect(frecent_groups).to be_nil
    end
  end
end
