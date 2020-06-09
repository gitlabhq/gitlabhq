# frozen_string_literal: true
require 'spec_helper'

describe 'getting Alert Management Alerts' do
  include GraphqlHelpers

  let_it_be(:payload) { { 'custom' => { 'alert' => 'payload' } } }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:resolved_alert) { create(:alert_management_alert, :all_fields, :resolved, project: project, issue: nil, severity: :low) }
  let_it_be(:triggered_alert) { create(:alert_management_alert, :all_fields, project: project, severity: :critical, payload: payload) }
  let_it_be(:other_project_alert) { create(:alert_management_alert, :all_fields) }
  let(:params) { {} }

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
      query_graphql_field('alertManagementAlerts', params, fields)
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
          'iid' => triggered_alert.iid.to_s,
          'issueIid' => triggered_alert.issue_iid.to_s,
          'title' => triggered_alert.title,
          'description' => triggered_alert.description,
          'severity' => triggered_alert.severity.upcase,
          'status' => 'TRIGGERED',
          'monitoringTool' => triggered_alert.monitoring_tool,
          'service' => triggered_alert.service,
          'hosts' => triggered_alert.hosts,
          'eventCount' => triggered_alert.events,
          'startedAt' => triggered_alert.started_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
          'endedAt' => nil,
          'details' => { 'custom.alert' => 'payload' },
          'createdAt' => triggered_alert.created_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
          'updatedAt' => triggered_alert.updated_at.strftime('%Y-%m-%dT%H:%M:%SZ')
        )

        expect(first_alert['assignees'].first).to include('username' => triggered_alert.assignees.first.username)

        expect(second_alert).to include(
          'iid' => resolved_alert.iid.to_s,
          'issueIid' => nil,
          'status' => 'RESOLVED',
          'endedAt' => resolved_alert.ended_at.strftime('%Y-%m-%dT%H:%M:%SZ')
        )
      end

      context 'with iid given' do
        let(:params) { { iid: resolved_alert.iid.to_s } }

        it_behaves_like 'a working graphql query'

        it { expect(alerts.size).to eq(1) }
        it { expect(first_alert['iid']).to eq(resolved_alert.iid.to_s) }
      end

      context 'with statuses given' do
        let(:params) { 'statuses: [TRIGGERED, ACKNOWLEDGED]' }

        it_behaves_like 'a working graphql query'

        it { expect(alerts.size).to eq(1) }
        it { expect(first_alert['iid']).to eq(triggered_alert.iid.to_s) }
      end

      context 'sorting data given' do
        let(:params) { 'sort: SEVERITY_DESC' }
        let(:iids) { alerts.map { |a| a['iid'] } }

        it_behaves_like 'a working graphql query'

        it 'sorts in the correct order' do
          expect(iids).to eq [resolved_alert.iid.to_s, triggered_alert.iid.to_s]
        end

        context 'ascending order' do
          let(:params) { 'sort: SEVERITY_ASC' }

          it 'sorts in the correct order' do
            expect(iids).to eq [triggered_alert.iid.to_s, resolved_alert.iid.to_s]
          end
        end
      end

      context 'searching' do
        let(:params) { { search: resolved_alert.title } }

        it_behaves_like 'a working graphql query'

        it { expect(alerts.size).to eq(1) }
        it { expect(first_alert['iid']).to eq(resolved_alert.iid.to_s) }

        context 'unknown criteria' do
          let(:params) { { search: 'something random' } }

          it { expect(alerts.size).to eq(0) }
        end
      end
    end

    context 'with alert_assignee flag disabled' do
      before do
        stub_feature_flags(alert_assignee: false)
        project.add_developer(current_user)

        post_graphql(query, current_user: current_user)
      end

      it 'excludes assignees' do
        expect(alerts.first['assignees']).to be_empty
      end
    end
  end
end
