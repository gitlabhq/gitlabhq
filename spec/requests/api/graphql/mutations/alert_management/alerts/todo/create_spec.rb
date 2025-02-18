# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a todo for the alert', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }

  let(:alert) { create(:alert_management_alert, project: project) }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: alert.iid.to_s
    }
    graphql_mutation(:alert_todo_create, variables) do
      <<~QL
         clientMutationId
         errors
         todo {
           author {
             username
           }
         }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:alert_todo_create) }

  it 'creates a todo for the current user' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['todo']['author']['username']).to eq(user.username)
  end

  context 'todo already exists' do
    before do
      post_graphql_mutation(mutation, current_user: user)
    end

    it 'surfaces an error' do
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['errors']).to eq(['You already have pending todo for this alert'])
    end
  end
end
