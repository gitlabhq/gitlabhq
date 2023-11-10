# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Unlink alert from an incident', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
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
      post_graphql_mutation(mutation, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to include(a_hash_including('message' => error))
    end
  end

  context 'when the user is allowed to update the incident' do
    before_all do
      project.add_developer(user)
    end

    shared_examples 'unlinking' do
      it 'unlinks the alert from the incident', :aggregate_failures do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expected_response = visible_remainded_alerts.map { |a| { 'id' => a.to_global_id.to_s } }
        expect(mutation_response.dig('issue', 'alertManagementAlerts', 'nodes')).to match_array(expected_response)

        expect(incident.reload.alert_management_alerts).to match_array(actual_remainded_alerts)
      end
    end

    context 'when the alert is internal' do
      let(:alert_to_unlink) { internal_alert }
      let(:actual_remainded_alerts) { [external_alert] }
      let(:visible_remainded_alerts) { [] } # The user cannot fetch external alerts without reading permissions

      it_behaves_like 'unlinking'
    end

    context 'when the alert is external' do
      let(:alert_to_unlink) { external_alert }
      let(:actual_remainded_alerts) { [internal_alert] }
      let(:visible_remainded_alerts) { [internal_alert] }

      it_behaves_like 'unlinking'
    end
  end
end
