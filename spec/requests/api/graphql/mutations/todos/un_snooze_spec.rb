# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Un-snoozing a todo', feature_category: :notifications do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:author) { create(:user) }
  let_it_be(:snoozed_until) { Time.utc(2024, 9, 12, 19, 0, 0) }
  let_it_be(:todo) do
    create(:todo, user: current_user, author: author, state: :pending, target: issue, snoozed_until: snoozed_until)
  end

  let_it_be(:other_user_todo_snoozed_until) { Time.utc(2024, 10, 5, 3, 0, 0) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:other_user_todo) do
    create(:todo, user: other_user, author: author, state: :pending, snoozed_until: other_user_todo_snoozed_until)
  end

  let(:input) { { id: todo.to_global_id.to_s } }
  let(:mutation) do
    graphql_mutation(
      :todo_un_snooze,
      input,
      <<-QL.strip_heredoc
        clientMutationId
        todo {
          id
        }
        errors
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:todo_un_snooze)
  end

  it 'un-snoozes the todo' do
    post_graphql_mutation(mutation, current_user: current_user)

    res = mutation_response['todo']

    expect(res['id']).to eq(todo.to_global_id.to_s)
    expect(res['snoozedUntil']).to be_nil
  end

  context 'when todo does not belong to requesting user' do
    let(:input) { { id: other_user_todo.to_global_id.to_s } }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not mutate the todo' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(other_user_todo.reload.snoozed_until).to eq(other_user_todo_snoozed_until)
    end
  end

  context 'when using an invalid gid' do
    let(:input) { { id: GitlabSchema.id_from_object(author).to_s } }
    let(:invalid_gid_error) { /"#{input[:id]}" does not represent an instance of #{todo.class}/ }

    it 'contains the expected error' do
      post_graphql_mutation(mutation, current_user: current_user)

      errors = json_response['errors']
      expect(errors).not_to be_blank
      expect(errors.first['message']).to match(invalid_gid_error)
    end
  end
end
