# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting Metrics Dashboard', feature_category: :metrics do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:project) { create(:project) }
  let(:environment) { create(:environment, project: project) }

  let(:query) do
    graphql_query_for(
      'project', { 'fullPath' => project.full_path },
      query_graphql_field(
        :environments, { 'name' => environment.name },
        query_graphql_field(
          :nodes, nil,
          query_graphql_field(
            :metricsDashboard, { 'path' => path },
            all_graphql_fields_for('MetricsDashboard'.classify)
          )
        )
      )
    )
  end

  context 'for anonymous user' do
    before do
      post_graphql(query, current_user: current_user)
    end

    context 'requested dashboard is available' do
      let(:path) { 'config/prometheus/common_metrics.yml' }

      it_behaves_like 'a working graphql query'

      it 'returns nil' do
        dashboard = graphql_data.dig('project', 'environments', 'nodes')

        expect(dashboard).to be_nil
      end
    end
  end

  context 'for user with developer access' do
    let(:remove_monitor_metrics) { false }

    before do
      stub_feature_flags(remove_monitor_metrics: remove_monitor_metrics)
      project.add_developer(current_user)
      post_graphql(query, current_user: current_user)
    end

    context 'requested dashboard is available' do
      let(:path) { 'config/prometheus/common_metrics.yml' }

      it_behaves_like 'a working graphql query'

      it 'returns metrics dashboard' do
        dashboard = graphql_data.dig('project', 'environments', 'nodes', 0, 'metricsDashboard')

        expect(dashboard).to eql("path" => path, "schemaValidationWarnings" => nil)
      end

      context 'invalid dashboard' do
        let(:path) { '.gitlab/dashboards/metrics.yml' }
        let(:project) { create(:project, :repository, :custom_repo, namespace: current_user.namespace, files: { path => "---\ndashboard: 'test'" }) }

        it 'returns metrics dashboard' do
          dashboard = graphql_data.dig('project', 'environments', 'nodes', 0, 'metricsDashboard')

          expect(dashboard).to eql("path" => path, "schemaValidationWarnings" => ["panel_groups: should be an array of panel_groups objects"])
        end
      end

      context 'empty dashboard' do
        let(:path) { '.gitlab/dashboards/metrics.yml' }
        let(:project) { create(:project, :repository, :custom_repo, namespace: current_user.namespace, files: { path => "" }) }

        it 'returns metrics dashboard' do
          dashboard = graphql_data.dig('project', 'environments', 'nodes', 0, 'metricsDashboard')

          expect(dashboard).to eql("path" => path, "schemaValidationWarnings" => ["dashboard: can't be blank", "panel_groups: should be an array of panel_groups objects"])
        end
      end

      context 'metrics dashboard feature is unavailable' do
        let(:remove_monitor_metrics) { true }

        it_behaves_like 'a working graphql query'

        it 'returns nil' do
          dashboard = graphql_data.dig('project', 'environments', 'nodes', 0, 'metricsDashboard')

          expect(dashboard).to be_nil
        end
      end
    end

    context 'requested dashboard can not be found' do
      let(:path) { 'config/prometheus/i_am_not_here.yml' }

      it_behaves_like 'a working graphql query'

      it 'returns nil' do
        dashboard = graphql_data.dig('project', 'environments', 'nodes', 0, 'metricsDashboard')

        expect(dashboard).to be_nil
      end
    end
  end
end
