# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'RunnerWebUrlEdge', feature_category: :runner_fleet do
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

    before do
      post_graphql(query, current_user: user, variables: { path: group.full_path })
    end

    context 'with an authorized user' do
      let(:user) { create_default(:user, :admin) }

      it_behaves_like 'a working graphql query'

      it 'returns correct URLs' do
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

      it_behaves_like 'a working graphql query'

      it 'returns no edges' do
        expect(edges_graphql_data).to be_empty
      end
    end
  end
end
