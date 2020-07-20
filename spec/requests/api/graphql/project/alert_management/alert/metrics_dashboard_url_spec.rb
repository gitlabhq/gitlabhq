# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Alert Management Alert Assignees' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let(:fields) do
    <<~QUERY
      nodes {
        iid
        metricsDashboardUrl
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

  let(:alerts) { graphql_data.dig('project', 'alertManagementAlerts', 'nodes') }
  let(:first_alert) { alerts.first }

  before do
    project.add_developer(current_user)
  end

  context 'with self-managed prometheus payload' do
    include_context 'self-managed prometheus alert attributes'

    before do
      create(:alert_management_alert, :prometheus, project: project, payload: payload)
    end

    it 'includes the correct metrics dashboard url' do
      post_graphql(graphql_query, current_user: current_user)

      expect(first_alert).to include('metricsDashboardUrl' => dashboard_url_for_alert)
    end
  end

  context 'with gitlab-managed prometheus payload' do
    include_context 'gitlab-managed prometheus alert attributes'

    before do
      create(:alert_management_alert, :prometheus, project: project, payload: payload, prometheus_alert: prometheus_alert)
    end

    it 'includes the correct metrics dashboard url' do
      post_graphql(graphql_query, current_user: current_user)

      expect(first_alert).to include('metricsDashboardUrl' => dashboard_url_for_alert)
    end
  end
end
