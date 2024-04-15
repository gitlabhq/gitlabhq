# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Marking todos done', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :pending, target: issue) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :done, target: issue) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :pending) }

  let(:input) { { id: todo1.to_global_id.to_s } }

  let(:mutation) do
    graphql_mutation(
      :todo_mark_done,
      input,
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
    graphql_mutation_response(:todo_mark_done)
  end

  it 'marks a single todo as done' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(todo1.reload.state).to eq('done')
    expect(todo2.reload.state).to eq('done')
    expect(other_user_todo.reload.state).to eq('pending')

    todo = mutation_response['todo']
    expect(todo['id']).to eq(todo1.to_global_id.to_s)
    expect(todo['state']).to eq('done')
  end

  context 'when todo is already marked done' do
    let(:input) { { id: todo2.to_global_id.to_s } }

    it 'has the expected response' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('done')
      expect(other_user_todo.reload.state).to eq('pending')

      todo = mutation_response['todo']
      expect(todo['id']).to eq(todo2.to_global_id.to_s)
      expect(todo['state']).to eq('done')
    end
  end

  context 'when todo does not belong to requesting user' do
    let(:input) { { id: other_user_todo.to_global_id.to_s } }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'results in the correct todo states' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('done')
      expect(other_user_todo.reload.state).to eq('pending')
    end
  end

  context 'when using an invalid gid' do
    let(:input) { { id: GitlabSchema.id_from_object(author).to_s } }
    let(:invalid_gid_error) { /"#{input[:id]}" does not represent an instance of #{todo1.class}/ }

    it 'contains the expected error' do
      post_graphql_mutation(mutation, current_user: current_user)

      errors = json_response['errors']
      expect(errors).not_to be_blank
      expect(errors.first['message']).to match(invalid_gid_error)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('done')
      expect(other_user_todo.reload.state).to eq('pending')
    end
  end
end
