# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an issue' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:assignee1) { create(:user) }
  let_it_be(:assignee2) { create(:user) }
  let_it_be(:project_label1) { create(:label, project: project) }
  let_it_be(:project_label2) { create(:label, project: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:new_label1) { FFaker::Lorem.word }
  let_it_be(:new_label2) { FFaker::Lorem.word }

  let(:input) do
    {
      'title' => 'new title',
      'description' => 'new description',
      'confidential' => true,
      'dueDate' => Date.tomorrow.strftime('%Y-%m-%d'),
      'type' => 'ISSUE'
    }
  end

  let(:mutation) { graphql_mutation(:createIssue, input.merge('projectPath' => project.full_path, 'locked' => true)) }

  let(:mutation_response) { graphql_mutation_response(:create_issue) }

  context 'the user is not allowed to create an issue' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create an issue' do
    before do
      project.add_developer(current_user)
    end

    it 'creates the issue' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']).to include(input)
      expect(mutation_response['issue']).to include('discussionLocked' => true)
    end
  end
end
