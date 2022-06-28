# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Todo Query' do
  include GraphqlHelpers

  let_it_be(:current_user) { nil }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let_it_be(:todo_owner) { create(:user) }

  let_it_be(:todo) { create(:todo, user: todo_owner, target: project) }

  before do
    project.add_developer(todo_owner)
  end

  let(:fields) do
    <<~GRAPHQL
      id
    GRAPHQL
  end

  let(:query) do
    graphql_query_for(:todo, { id: todo.to_global_id.to_s }, fields)
  end

  subject do
    result = GitlabSchema.execute(query, context: { current_user: current_user }).to_h
    graphql_dig_at(result, :data, :todo)
  end

  context 'when requesting user is todo owner' do
    let(:current_user) { todo_owner }

    it { is_expected.to include('id' => todo.to_global_id.to_s) }
  end

  context 'when requesting user is not todo owner' do
    let(:current_user) { create(:user) }

    it { is_expected.to be_nil }
  end

  context 'when unauthenticated' do
    it { is_expected.to be_nil }
  end
end
