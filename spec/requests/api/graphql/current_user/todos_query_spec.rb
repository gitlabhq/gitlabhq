# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query current user todos' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:commit_todo) { create(:on_commit_todo, user: current_user, project: create(:project, :repository)) }
  let_it_be(:issue_todo) { create(:todo, user: current_user, target: create(:issue)) }
  let_it_be(:merge_request_todo) { create(:todo, user: current_user, target: create(:merge_request)) }
  let_it_be(:design_todo) { create(:todo, user: current_user, target: create(:design)) }

  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('todos'.classify)}
    }
    QUERY
  end

  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('todos', {}, fields))
  end

  subject { graphql_data.dig('currentUser', 'todos', 'nodes') }

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'contains the expected ids' do
    is_expected.to include(
      a_hash_including('id' => commit_todo.to_global_id.to_s),
      a_hash_including('id' => issue_todo.to_global_id.to_s),
      a_hash_including('id' => merge_request_todo.to_global_id.to_s),
      a_hash_including('id' => design_todo.to_global_id.to_s)
    )
  end

  it 'returns Todos for all target types' do
    is_expected.to include(
      a_hash_including('targetType' => 'COMMIT'),
      a_hash_including('targetType' => 'ISSUE'),
      a_hash_including('targetType' => 'MERGEREQUEST'),
      a_hash_including('targetType' => 'DESIGN')
    )
  end
end
