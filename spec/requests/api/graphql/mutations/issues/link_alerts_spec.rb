# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Link alerts to an incident', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:planner) { create(:user, planner_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:linked_alert) { create(:alert_management_alert, project: project) }
  let_it_be(:alert1) { create(:alert_management_alert, project: project) }
  let_it_be(:alert2) { create(:alert_management_alert, project: project) }
  let_it_be(:incident) { create(:incident, project: project, alert_management_alerts: [linked_alert]) }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: incident.iid.to_s,
      alert_references: [alert1.to_reference, alert2.details_url]
    }

    graphql_mutation(
      :issue_link_alerts,
      variables,
      <<-QL.strip_heredoc
        clientMutationId
        errors
        issue {
          iid
          alertManagementAlerts {
            nodes {
              iid
            }
          }
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_link_alerts)
  end

  context 'when the user is not allowed to update the incident' do
    it 'returns an error' do
      error = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      post_graphql_mutation(mutation, current_user: planner)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to include(a_hash_including('message' => error))
    end
  end

  context 'when the user is allowed to update the incident' do
    before do
      stub_feature_flags(hide_incident_management_features: false)
    end

    it 'links alerts to the incident' do
      post_graphql_mutation(mutation, current_user: developer)

      expect(response).to have_gitlab_http_status(:success)
      expected_response = [linked_alert, alert1, alert2].map { |a| { 'iid' => a.iid.to_s } }
      expect(mutation_response.dig('issue', 'alertManagementAlerts', 'nodes')).to match_array(expected_response)
    end
  end

  context 'when hide_incident_management_features flag is enabled' do
    it 'does not return alertManagementAlerts and raises a GraphQL error' do
      post_graphql_mutation(mutation, current_user: developer)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response.dig('issue', 'alertManagementAlerts')).to be_nil

      parsed_errors = Gitlab::Json.parse(response.body)['errors']
      expect(parsed_errors).to include(
        a_hash_including('message' => a_string_matching(/Field 'alertManagementAlerts' doesn't exist/))
      )
    end
  end
end
