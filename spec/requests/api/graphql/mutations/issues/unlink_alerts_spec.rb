# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Unlink alert from an incident', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:planner) { create(:user, planner_of: project) }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:another_project) { create(:project) }
  let_it_be(:internal_alert) { create(:alert_management_alert, project: project) }
  let_it_be(:external_alert) { create(:alert_management_alert, project: another_project) }
  let_it_be(:incident) do
    create(:incident, project: project, alert_management_alerts: [internal_alert, external_alert])
  end

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: incident.iid.to_s,
      alert_id: alert_to_unlink.to_global_id.to_s
    }

    graphql_mutation(
      :issue_unlink_alert,
      variables,
      <<-QL.strip_heredoc
        clientMutationId
        errors
        issue {
          iid
          alertManagementAlerts {
            nodes {
              id
            }
          }
        }
      QL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_unlink_alert)
  end

  context 'when the user is not allowed to update the incident' do
    let(:alert_to_unlink) { internal_alert }

    it 'returns an error' do
      error = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      post_graphql_mutation(mutation, current_user: planner)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to include(a_hash_including('message' => error))
    end
  end

  context 'when the user is allowed to update the incident' do
    shared_examples 'unlinking' do
      context 'when hide_incident_management_features is disabled' do
        before do
          stub_feature_flags(hide_incident_management_features: false)
        end

        it 'unlinks the alert from the incident', :aggregate_failures do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expected_response = visible_remainded_alerts.map { |a| { 'id' => a.to_global_id.to_s } }
          expect(mutation_response.dig('issue', 'alertManagementAlerts', 'nodes')).to match_array(expected_response)

          expect(incident.reload.alert_management_alerts).to match_array(actual_remainded_alerts)
        end
      end

      context 'when hide_incident_management_features is enabled' do
        it 'does not return alert data and raises a GraphQL error', :aggregate_failures do
          post_graphql_mutation(mutation, current_user: current_user)
          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response.dig('issue', 'alertManagementAlerts', 'nodes')).to be_nil

          parsed_errors = Gitlab::Json.parse(response.body)['errors']
          expect(parsed_errors).to include(
            a_hash_including('message' => a_string_matching(/Field 'alertManagementAlerts' doesn't exist/))
          )
        end
      end
    end

    context 'when the alert is internal' do
      let(:current_user) { reporter }
      let(:alert_to_unlink) { internal_alert }
      let(:actual_remainded_alerts) { [external_alert] }
      let(:visible_remainded_alerts) { [] } # The user cannot fetch external alerts without reading permissions

      it_behaves_like 'unlinking'
    end

    context 'when the alert is external' do
      let(:current_user) { developer }
      let(:alert_to_unlink) { external_alert }
      let(:actual_remainded_alerts) { [internal_alert] }
      let(:visible_remainded_alerts) { [internal_alert] }

      it_behaves_like 'unlinking'
    end
  end
end
