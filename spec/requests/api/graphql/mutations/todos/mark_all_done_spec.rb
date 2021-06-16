# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Marking all todos done' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:other_user2) { create(:user) }

  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :pending) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :done) }
  let_it_be(:todo3) { create(:todo, user: current_user, author: author, state: :pending) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :pending) }

  let(:input) { {} }

  let(:mutation) do
    graphql_mutation(:todos_mark_all_done, input,
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

    updated_todo_ids = mutation_response['todos'].map { |todo| todo['id'] }
    expect(updated_todo_ids).to contain_exactly(global_id_of(todo1), global_id_of(todo3))
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
end
