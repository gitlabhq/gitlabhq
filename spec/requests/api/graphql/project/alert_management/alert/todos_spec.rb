# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Alert Management Alert Assignees', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, developer_of: project) }
  let_it_be(:alert) { create(:alert_management_alert, project: project) }
  let_it_be(:other_alert) { create(:alert_management_alert, project: project) }
  let_it_be(:todo) { create(:todo, :pending, target: alert, user: current_user, project: project) }
  let_it_be(:other_todo) { create(:todo, :pending, target: other_alert, user: current_user, project: project) }

  let(:fields) do
    <<~QUERY
      nodes {
        iid
        todos {
          nodes {
            id
          }
        }
      }
    QUERY
  end

  let(:graphql_query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementAlerts', {}, fields)
    )
  end

  let(:gql_alerts) { graphql_data.dig('project', 'alertManagementAlerts', 'nodes') }
  let(:gql_todos) { gql_alerts.to_h { |gql_alert| [gql_alert['iid'], gql_alert['todos']['nodes']] } }
  let(:gql_alert_todo) { gql_todos[alert.iid.to_s].first }
  let(:gql_other_alert_todo) { gql_todos[other_alert.iid.to_s].first }

  it 'includes the correct metrics dashboard url' do
    post_graphql(graphql_query, current_user: current_user)

    expect(gql_alert_todo['id']).to eq(todo.to_global_id.to_s)
    expect(gql_other_alert_todo['id']).to eq(other_todo.to_global_id.to_s)
  end
end
