# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting all done todos', :disable_rate_limiter, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:todo1) { create(:todo, user: current_user, author: author, state: :done) }
  let_it_be(:todo2) { create(:todo, user: current_user, author: author, state: :done) }

  let(:input) { {} }
  let(:mutation) { graphql_mutation(:todo_delete_all_done, input, 'errors') }

  def mutation_response
    graphql_mutation_response(:todo_delete_all_done)
  end

  it_behaves_like 'authorizing granular token permissions for GraphQL', :delete_todo do
    let(:user) { current_user }
    let(:boundary_object) { :user }
    let(:mutation) { graphql_mutation(:todo_delete_all_done, input, 'errors') }
    let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
  end

  it 'schedules deletion of all done todos' do
    expect(::Todos::DeleteAllDoneWorker).to receive(:perform_async).with(current_user.id, anything)

    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response['errors']).to be_empty
  end
end
