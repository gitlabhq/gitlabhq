# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting the status of an alert', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }

  let(:alert) { create(:alert_management_alert, project: project) }
  let(:input) { { status: 'ACKNOWLEDGED' } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: alert.iid.to_s
    }
    graphql_mutation(:update_alert_status, variables.merge(input)) do
      <<~QL
         clientMutationId
         errors
         alert {
           iid
           status
         }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:update_alert_status) }

  it 'updates the status of the alert' do
    post_graphql_mutation(mutation, current_user: user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['alert']['status']).to eq(input[:status])
  end
end
