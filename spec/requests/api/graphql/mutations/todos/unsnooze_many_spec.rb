# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Unsnoozing many Todos', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:author) { create(:user) }

  let_it_be_with_reload(:todo1) do
    create(:todo, user: current_user, author: author, state: :pending, target: issue, snoozed_until: 1.day.from_now)
  end

  let_it_be_with_reload(:todo2) do
    create(:todo, user: current_user, author: author, state: :pending, target: issue, snoozed_until: 1.day.from_now)
  end

  let(:input_ids) { [todo1, todo2].map { |obj| global_id_of(obj) } }
  let(:input) { { ids: input_ids } }

  let(:mutation) do
    graphql_mutation(
      :todo_unsnooze_many,
      input,
      <<-QL.strip_heredoc
        clientMutationId
        errors
        todos { id }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:todo_unsnooze_many)
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :update_todo do
    let(:user) { current_user }
    let(:boundary_object) { :user }
    let(:mutation) { graphql_mutation(:todo_unsnooze_many, input, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  it 'unsnoozes many todos' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(todo1.reload.snoozed_until).to be_nil
    expect(todo2.reload.snoozed_until).to be_nil

    expect(mutation_response).to include(
      'errors' => be_empty,
      'todos' => contain_exactly(
        a_graphql_entity_for(todo1),
        a_graphql_entity_for(todo2)
      )
    )
  end
end
