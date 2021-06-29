# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'A Todoable that implements the CurrentUserTodos interface' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:todoable) { create(:issue, project: project) }
  let_it_be(:done_todo) { create(:todo, state: :done, target: todoable, user: current_user) }
  let_it_be(:pending_todo) { create(:todo, state: :pending, target: todoable, user: current_user) }

  let(:state) { 'null' }

  let(:todoable_response) do
    graphql_data_at(:project, :issue, :currentUserTodos, :nodes)
  end

  let(:query) do
    <<~GQL
      {
        project(fullPath: "#{project.full_path}") {
          issue(iid: "#{todoable.iid}") {
            currentUserTodos(state: #{state}) {
              nodes {
                #{all_graphql_fields_for('Todo', max_depth: 1)}
              }
            }
          }
        }
      }
    GQL
  end

  it 'returns todos of the current user' do
    post_graphql(query, current_user: current_user)

    expect(todoable_response).to contain_exactly(
      a_hash_including('id' => global_id_of(done_todo)),
      a_hash_including('id' => global_id_of(pending_todo))
    )
  end

  it 'does not return todos of another user', :aggregate_failures do
    post_graphql(query, current_user: create(:user))

    expect(response).to have_gitlab_http_status(:success)
    expect(todoable_response).to be_empty
  end

  it 'does not error when there is no logged in user', :aggregate_failures do
    post_graphql(query)

    expect(response).to have_gitlab_http_status(:success)
    expect(todoable_response).to be_empty
  end

  context 'when `state` argument is `pending`' do
    let(:state) { 'pending' }

    it 'returns just the pending todo' do
      post_graphql(query, current_user: current_user)

      expect(todoable_response).to contain_exactly(
        a_hash_including('id' => global_id_of(pending_todo))
      )
    end
  end

  context 'when `state` argument is `done`' do
    let(:state) { 'done' }

    it 'returns just the done todo' do
      post_graphql(query, current_user: current_user)

      expect(todoable_response).to contain_exactly(
        a_hash_including('id' => global_id_of(done_todo))
      )
    end
  end
end
