# frozen_string_literal: true
require 'spec_helper'

describe 'getting Alert Management Alerts' do
  include GraphqlHelpers

  let_it_be(:payload) { { 'custom' => { 'alert' => 'payload' } } }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:alert_1) { create(:alert_management_alert, :all_fields, :resolved, project: project, severity: :low) }
  let_it_be(:alert_2) { create(:alert_management_alert, :all_fields, project: project, severity: :critical, payload: payload) }
  let_it_be(:other_project_alert) { create(:alert_management_alert, :all_fields) }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('AlertManagementAlert'.classify)}
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementAlerts', {}, fields)
    )
  end

  context 'with alert data' do
    let(:alerts) { graphql_data.dig('project', 'alertManagementAlerts', 'nodes') }

    context 'without project permissions' do
      let(:user) { create(:user) }

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it { expect(alerts).to be nil }
    end

    context 'with project permissions' do
      before do
        project.add_developer(current_user)
        post_graphql(query, current_user: current_user)
      end

      let(:first_alert) { alerts.first }
      let(:second_alert) { alerts.second }

      it_behaves_like 'a working graphql query'

      it { expect(alerts.size).to eq(2) }

      it 'returns the correct properties of the alerts' do
        expect(first_alert).to include(
          'iid' => alert_2.iid.to_s,
          'title' => alert_2.title,
          'description' => alert_2.description,
          'severity' => alert_2.severity.upcase,
          'status' => 'TRIGGERED',
          'monitoringTool' => alert_2.monitoring_tool,
          'service' => alert_2.service,
          'hosts' => alert_2.hosts,
          'eventCount' => alert_2.events,
          'startedAt' => alert_2.started_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
          'endedAt' => nil,
          'details' => { 'custom.alert' => 'payload' },
          'createdAt' => alert_2.created_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
          'updatedAt' => alert_2.updated_at.strftime('%Y-%m-%dT%H:%M:%SZ')
        )

        expect(second_alert).to include(
          'status' => 'RESOLVED',
          'endedAt' => alert_1.ended_at.strftime('%Y-%m-%dT%H:%M:%SZ')
        )
      end

      context 'with iid given' do
        let(:query) do
          graphql_query_for(
            'project',
            { 'fullPath' => project.full_path },
            query_graphql_field('alertManagementAlerts', { iid: alert_1.iid.to_s }, fields)
          )
        end

        it_behaves_like 'a working graphql query'

        it { expect(alerts.size).to eq(1) }
        it { expect(first_alert['iid']).to eq(alert_1.iid.to_s) }
      end

      context 'sorting data given' do
        let(:query) do
          graphql_query_for(
            'project',
            { 'fullPath' => project.full_path },
            query_graphql_field('alertManagementAlerts', params, fields)
          )
        end

        let(:params) { 'sort: SEVERITY_DESC' }
        let(:iids) { alerts.map { |a| a['iid'] } }

        it_behaves_like 'a working graphql query'

        it 'sorts in the correct order' do
          expect(iids).to eq [alert_1.iid.to_s, alert_2.iid.to_s]
        end

        context 'ascending order' do
          let(:params) { 'sort: SEVERITY_ASC' }

          it 'sorts in the correct order' do
            expect(iids).to eq [alert_2.iid.to_s, alert_1.iid.to_s]
          end
        end
      end
    end
  end
end
