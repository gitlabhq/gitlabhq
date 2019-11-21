# frozen_string_literal: true

require 'spec_helper'

describe 'Restoring Todos' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :done) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :pending) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :done) }

  let(:input) { { id: todo1.to_global_id.to_s } }

  let(:mutation) do
    graphql_mutation(:todo_restore, input,
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       todo {
                         id
                         state
                       }
                     QL
    )
  end

  def mutation_response
    graphql_mutation_response(:todo_restore)
  end

  it 'restores a single todo' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(todo1.reload.state).to eq('pending')
    expect(todo2.reload.state).to eq('pending')
    expect(other_user_todo.reload.state).to eq('done')

    todo = mutation_response['todo']
    expect(todo['id']).to eq(todo1.to_global_id.to_s)
    expect(todo['state']).to eq('pending')
  end

  context 'when todo is already marked pending' do
    let(:input) { { id: todo2.to_global_id.to_s } }

    it 'has the expected response' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')

      todo = mutation_response['todo']
      expect(todo['id']).to eq(todo2.to_global_id.to_s)
      expect(todo['state']).to eq('pending')
    end
  end

  context 'when todo does not belong to requesting user' do
    let(:input) { { id: other_user_todo.to_global_id.to_s } }
    let(:access_error) { 'The resource that you are attempting to access does not exist or you don\'t have permission to perform this action' }

    it 'contains the expected error' do
      post_graphql_mutation(mutation, current_user: current_user)

      errors = json_response['errors']
      expect(errors).not_to be_blank
      expect(errors.first['message']).to eq(access_error)

      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')
    end
  end

  context 'when using an invalid gid' do
    let(:input) { { id: 'invalid_gid' } }
    let(:invalid_gid_error) { 'invalid_gid is not a valid GitLab id.' }

    it 'contains the expected error' do
      post_graphql_mutation(mutation, current_user: current_user)

      errors = json_response['errors']
      expect(errors).not_to be_blank
      expect(errors.first['message']).to eq(invalid_gid_error)

      expect(todo1.reload.state).to eq('done')
      expect(todo2.reload.state).to eq('pending')
      expect(other_user_todo.reload.state).to eq('done')
    end
  end
end
