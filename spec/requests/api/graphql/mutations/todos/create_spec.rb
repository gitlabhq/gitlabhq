# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a todo', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:target) { create(:issue) }

  let(:input) do
    {
      'targetId' => target.to_global_id.to_s
    }
  end

  let(:mutation) { graphql_mutation(:todoCreate, input) }

  let(:mutation_response) { graphql_mutation_response(:todoCreate) }

  context 'the user is not allowed to create todo' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create todo' do
    before do
      target.project.add_guest(current_user)
    end

    it 'creates todo' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['todo']['body']).to eq(target.title)
      expect(mutation_response['todo']['state']).to eq('pending')
    end
  end
end
