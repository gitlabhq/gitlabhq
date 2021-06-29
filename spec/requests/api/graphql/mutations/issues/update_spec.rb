# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update of an existing issue' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:input) do
    {
      'iid' => issue.iid.to_s,
      'title' => 'new title',
      'description' => 'new description',
      'confidential' => true,
      'dueDate' => Date.tomorrow.strftime('%Y-%m-%d'),
      'type' => 'ISSUE'
    }
  end

  let(:mutation) { graphql_mutation(:update_issue, input.merge(project_path: project.full_path, locked: true)) }
  let(:mutation_response) { graphql_mutation_response(:update_issue) }

  context 'the user is not allowed to update issue' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to update issue' do
    before do
      project.add_developer(current_user)
    end

    it 'updates the issue' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']).to include(input)
      expect(mutation_response['issue']).to include('discussionLocked' => true)
    end
  end
end
