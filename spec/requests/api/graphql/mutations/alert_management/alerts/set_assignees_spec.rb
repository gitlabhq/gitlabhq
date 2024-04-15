# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting assignees of an alert', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:alert) { create(:alert_management_alert, project: project) }

  let(:input) { { assignee_usernames: [current_user.username] } }

  let(:mutation) do
    graphql_mutation(
      :alert_set_assignees,
      { project_path: project.full_path, iid: alert.iid.to_s }.merge(input),
      <<~QL
       clientMutationId
       errors
       alert {
         assignees {
           nodes {
             username
           }
         }
       }
      QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:alert_set_assignees) }

  it 'updates the assignee of the alert' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['alert']['assignees']['nodes'].first['username']).to eq(current_user.username)
    expect(alert.reload.assignees).to contain_exactly(current_user)
  end

  context 'with operation_mode specified' do
    let(:input) do
      {
        assignee_usernames: [current_user.username],
        operation_mode: Types::MutationOperationModeEnum.enum[:remove]
      }
    end

    before do
      alert.assignees = [current_user]
    end

    it 'updates the assignee of the alert' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['alert']['assignees']['nodes']).to be_empty
      expect(alert.reload.assignees).to be_empty
    end
  end
end
