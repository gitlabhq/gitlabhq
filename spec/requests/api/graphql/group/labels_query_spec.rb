# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting group label information', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:label_factory) { :group_label }
  let_it_be(:label_attrs) { { group: group } }

  it_behaves_like 'querying a GraphQL type with labels' do
    let(:path_prefix) { ['group'] }

    def make_query(fields)
      graphql_query_for('group', { full_path: group.full_path }, fields)
    end
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', [:read_group, :read_label] do
    let_it_be(:user) { create(:user) }
    let_it_be(:label) { create(:group_label, group: group) }
    let(:boundary_object) { group }
    let(:query) do
      graphql_query_for('group', { full_path: group.full_path }, [
        query_graphql_field(:labels, nil, 'nodes { id }')
      ])
    end

    let(:request) { post_graphql(query, token: { personal_access_token: pat }) }

    before_all { group.add_developer(user) }
  end
end
