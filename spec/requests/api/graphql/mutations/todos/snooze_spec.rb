# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Snoozing a todo', feature_category: :notifications do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:author) { create(:user) }
  let_it_be(:todo) { create(:todo, user: current_user, author: author, state: :pending, target: issue) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:other_user_todo) { create(:todo, user: other_user, author: author, state: :pending) }
  let_it_be(:snooze_until) { Time.utc(2024, 9, 12, 19, 0, 0) }

  let(:input) { { id: todo.to_global_id.to_s, snooze_until: snooze_until } }
  let(:mutation) do
    graphql_mutation(
      :todo_snooze,
      input,
      <<-QL.strip_heredoc
        clientMutationId
        todo {
          id
          snoozedUntil
        }
        errors
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:todo_snooze)
  end

  it 'snoozes the todo until the specified time' do
    post_graphql_mutation(mutation, current_user: current_user)

    res = mutation_response['todo']

    expect(res['id']).to eq(todo.to_global_id.to_s)
    expect(DateTime.strptime(res['snoozedUntil'])).to eq(snooze_until)
  end

  context 'when todo does not belong to requesting user' do
    let(:input) { { id: other_user_todo.to_global_id.to_s, snooze_until: snooze_until } }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not mutate the todo' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(other_user_todo.reload.snoozed_until).to be_nil
    end
  end

  context 'when using an invalid gid' do
    let(:input) { { id: GitlabSchema.id_from_object(author).to_s, snooze_until: snooze_until } }
    let(:invalid_gid_error) { /"#{input[:id]}" does not represent an instance of #{todo.class}/ }

    it 'contains the expected error' do
      post_graphql_mutation(mutation, current_user: current_user)

      errors = json_response['errors']
      expect(errors).not_to be_blank
      expect(errors.first['message']).to match(invalid_gid_error)
    end
  end
end
