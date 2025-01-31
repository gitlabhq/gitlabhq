# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Resolving many Todos', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:author) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be_with_reload(:todo1) { create(:todo, user: current_user, author: author, state: :pending, target: issue) }
  let_it_be_with_reload(:todo2) { create(:todo, user: current_user, author: author, state: :pending, target: issue) }

  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :pending) }

  let(:input_ids) { [todo1, todo2].map { |obj| global_id_of(obj) } }
  let(:input) { { ids: input_ids } }

  let(:mutation) do
    graphql_mutation(
      :todo_resolve_many,
      input,
      <<-QL.strip_heredoc
        clientMutationId
        errors
        todos {
          id
          state
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:todo_resolve_many)
  end

  it 'resolves many todos' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(todo1.reload.state).to eq('done')
    expect(todo2.reload.state).to eq('done')
    expect(other_user_todo.reload.state).to eq('pending')

    expect(mutation_response).to include(
      'errors' => be_empty,
      'todos' => contain_exactly(
        a_graphql_entity_for(todo1, 'state' => 'done'),
        a_graphql_entity_for(todo2, 'state' => 'done')
      )
    )
  end

  context 'when using an invalid gid' do
    let(:input_ids) { [global_id_of(author)] }
    let(:invalid_gid_error) { /does not represent an instance of #{todo1.class}/ }

    it 'contains the expected error' do
      post_graphql_mutation(mutation, current_user: current_user)

      errors = json_response['errors']
      expect(errors).not_to be_blank
      expect(errors.first['message']).to match(invalid_gid_error)

      expect(todo1.reload.state).to eq('pending')
      expect(todo2.reload.state).to eq('pending')
    end
  end
end
