# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting Alert Management Alert counts by status' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:alert_resolved) { create(:alert_management_alert, :resolved, project: project) }
  let_it_be(:alert_triggered) { create(:alert_management_alert, project: project) }
  let_it_be(:other_project_alert) { create(:alert_management_alert) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('AlertManagementAlertStatusCountsType'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementAlertStatusCounts', params, fields)
    )
  end

  context 'with alert data' do
    let(:alert_counts) { graphql_data.dig('project', 'alertManagementAlertStatusCounts') }

    context 'without project permissions' do
      let(:user) { create(:user) }

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'
      it { expect(alert_counts).to be nil }
    end

    context 'with project permissions' do
      before do
        project.add_developer(current_user)
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'
      it 'returns the correct counts for each status' do
        expect(alert_counts).to eq(
          'open' => 1,
          'all' => 2,
          'triggered' => 1,
          'acknowledged' => 0,
          'resolved' => 1,
          'ignored' => 0
        )
      end

      context 'with search criteria' do
        let(:params) { { search: alert_resolved.title } }

        it_behaves_like 'a working graphql query'
        it 'returns the correct counts for each status' do
          expect(alert_counts).to eq(
            'open' => 0,
            'all' => 1,
            'triggered' => 0,
            'acknowledged' => 0,
            'resolved' => 1,
            'ignored' => 0
          )
        end
      end
    end
  end
end
