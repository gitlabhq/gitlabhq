# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete a timelog', feature_category: :team_planning do
  include GraphqlHelpers
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:timelog) { create(:timelog, user: author, issue: issue, time_spent: 1800) }

  let(:current_user) { nil }
  let(:mutation) { graphql_mutation(:timelogDelete, { 'id' => timelog.to_global_id.to_s }) }
  let(:mutation_response) { graphql_mutation_response(:timelog_delete) }

  context 'when the user is not allowed to delete a timelog' do
    let(:current_user) { create(:user) }

    before do
      post_graphql_mutation(mutation, current_user: current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to delete a timelog' do
    let(:current_user) { author }

    it 'deletes the timelog' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change(Timelog, :count).by(-1)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['timelog']).to include('id' => timelog.to_global_id.to_s)
    end
  end
end
