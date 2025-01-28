# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group(fullPath).environmentScopes', feature_category: :ci_variables do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let(:expected_environment_scopes) do
    %w[
      group1_environment1
      group1_environment2
      group2_environment3
      group2_environment4
      group2_environment5
      group2_environment6
    ]
  end

  let(:query) do
    %(
      query {
        group(fullPath: "#{group.full_path}") {
          environmentScopes#{environment_scopes_params} {
            nodes {
              name
            }
          }
        }
      }
    )
  end

  before do
    expected_environment_scopes.each_with_index do |env, index|
      create(:ci_group_variable, group: group, key: "var#{index + 1}", environment_scope: env)
    end
  end

  context 'when the user can administer the group' do
    before do
      group.add_owner(user)
    end

    context 'when query has no parameters' do
      let(:environment_scopes_params) { "" }

      it 'returns all avaiable environment scopes' do
        post_graphql(query, current_user: user)

        expect(graphql_data.dig('group', 'environmentScopes', 'nodes')).to eq(
          expected_environment_scopes.map { |env_scope| { 'name' => env_scope } }
        )
      end
    end

    context 'when query has search parameters' do
      let(:environment_scopes_params) { "(search: \"group1\")" }

      it 'returns only environment scopes with group1 prefix' do
        post_graphql(query, current_user: user)

        expect(graphql_data.dig('group', 'environmentScopes', 'nodes')).to eq(
          [
            { 'name' => 'group1_environment1' },
            { 'name' => 'group1_environment2' }
          ]
        )
      end
    end
  end

  context 'when the user cannot administer the group' do
    let(:environment_scopes_params) { "" }

    before do
      group.add_developer(user)
    end

    it 'returns nothing' do
      post_graphql(query, current_user: user)

      expect(graphql_data.dig('group', 'environmentScopes')).to be_nil
    end
  end
end
