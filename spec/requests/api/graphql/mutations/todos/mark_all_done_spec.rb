# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Marking all todos done', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:other_user2) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :pending, target: issue) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :done, target: issue) }
  let_it_be(:todo3) { create(:todo, user: current_user, author: author, state: :pending, target: issue) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :pending) }

  let(:input) { {} }

  let(:mutation) do
    graphql_mutation(
      :todos_mark_all_done,
      input,
      <<-QL.strip_heredoc
        clientMutationId
        todos { id }
        errors
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:todos_mark_all_done)
  end

  it 'marks all pending todos as done' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(todo1.reload.state).to eq('done')
    expect(todo2.reload.state).to eq('done')
    expect(todo3.reload.state).to eq('done')
    expect(other_user_todo.reload.state).to eq('pending')

    updated_todos = mutation_response['todos']
    expect(updated_todos).to contain_exactly(a_graphql_entity_for(todo1), a_graphql_entity_for(todo3))
  end

  context 'when target_id is given', :aggregate_failures do
    let_it_be(:target) { create(:issue, project: project) }
    let_it_be(:target_todo1) { create(:todo, user: current_user, author: author, state: :pending, target: target) }
    let_it_be(:target_todo2) { create(:todo, user: current_user, author: author, state: :pending, target: target) }

    let(:input) { { 'targetId' => target.to_global_id.to_s } }

    it 'marks all pending todos for the target as done' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(target_todo1.reload.state).to eq('done')
      expect(target_todo2.reload.state).to eq('done')

      expect(todo1.reload.state).to eq('pending')
      expect(todo3.reload.state).to eq('pending')

      updated_todos = mutation_response['todos']
      expect(updated_todos).to contain_exactly(a_graphql_entity_for(target_todo1), a_graphql_entity_for(target_todo2))
    end

    context 'when target does not exist' do
      let(:input) { { 'targetId' => "gid://gitlab/Issue/#{non_existing_record_id}" } }

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to include(a_hash_including('message' => include('Resource not available')))
      end
    end
  end

  it 'behaves as expected if there are no todos for the requesting user' do
    post_graphql_mutation(mutation, current_user: other_user2)

    expect(todo1.reload.state).to eq('pending')
    expect(todo2.reload.state).to eq('done')
    expect(todo3.reload.state).to eq('pending')
    expect(other_user_todo.reload.state).to eq('pending')

    updated_todo_ids = mutation_response['todos']
    expect(updated_todo_ids).to be_empty
  end

  context 'when user is not logged in' do
    let(:current_user) { nil }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when filtering by a specific group' do
    let_it_be(:todo4) do
      create(:todo, user: current_user, author: author, state: :pending, target: issue, group: group)
    end

    let(:input) { { 'groupId' => group.id } }

    it 'resolves to-dos for that group only' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(todo1.reload.state).to eq('pending')
      expect(todo3.reload.state).to eq('pending')
      expect(todo4.reload.state).to eq('done')
    end
  end
end
