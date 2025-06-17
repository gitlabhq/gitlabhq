# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an alert issue from an alert', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }
  let_it_be(:alert) { create(:alert_management_alert, project: project) }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: alert.iid.to_s
    }
    graphql_mutation(
      :create_alert_issue,
      variables,
      <<~QL
        clientMutationId
        errors
        alert {
          iid
          issue {
            iid
          }
        }
        issue {
          iid
          title
        }
      QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:create_alert_issue) }

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(hide_incident_management_features: false)
    end

    context 'when there is no issue associated with the alert' do
      it 'creates an alert issue' do
        post_graphql_mutation(mutation, current_user: user)

        new_issue = Issue.last!

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response.slice('alert', 'issue')).to eq(
          'alert' => {
            'iid' => alert.iid.to_s,
            'issue' => { 'iid' => new_issue.iid.to_s }
          },
          'issue' => {
            'iid' => new_issue.iid.to_s,
            'title' => new_issue.title
          }
        )
      end
    end

    context 'when there is an issue already associated with the alert' do
      before do
        AlertManagement::CreateAlertIssueService.new(alert, user).execute
      end

      it 'responds with an error' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response.slice('errors', 'issue')).to eq(
          'errors' => ['An issue already exists'],
          'issue' => nil
        )
      end
    end
  end

  context 'when feature flag is enabled' do
    it 'raises a resource not available error' do
      post_graphql_mutation(mutation, current_user: user)

      expect_graphql_errors_to_include("This feature is not available")
    end
  end
end
