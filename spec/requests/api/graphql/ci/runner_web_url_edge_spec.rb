# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'RunnerWebUrlEdge', feature_category: :fleet_visibility do
  include GraphqlHelpers

  describe 'inside a Query.group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }

    let(:edges_graphql_data) { graphql_data.dig('group', 'runners', 'edges') }

    let(:query) do
      <<~GQL
        query($path: ID!) {
          group(fullPath: $path) {
            runners {
              edges {
                editUrl
                webUrl
              }
            }
          }
        }
      GQL
    end

    subject(:request) do
      post_graphql(query, current_user: user, variables: { path: group.full_path })
    end

    context 'with an authorized user' do
      let(:user) { create_default(:user, :admin) }

      it_behaves_like 'a working graphql query' do
        before do
          request
        end
      end

      it 'returns correct URLs' do
        request

        expect(edges_graphql_data).to match_array [
          {
            'editUrl' => Gitlab::Routing.url_helpers.edit_group_runner_url(group, group_runner),
            'webUrl' => Gitlab::Routing.url_helpers.group_runner_url(group, group_runner)
          }
        ]
      end
    end

    context 'with an unauthorized user' do
      let(:user) { create(:user) }

      it 'returns nil runners and an error' do
        request

        expect(graphql_data.dig('group', 'runners')).to be_nil
        expect(graphql_errors).to contain_exactly(a_hash_including(
          'message' => a_string_including("you don't have permission to perform this action"),
          'path' => %w[group runners]
        ))
      end
    end
  end
end
