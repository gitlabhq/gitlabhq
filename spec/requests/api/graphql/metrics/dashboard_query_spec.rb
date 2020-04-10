# frozen_string_literal: true

require 'spec_helper'

describe 'Getting Metrics Dashboard' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let(:project) { create(:project) }
  let!(:environment) { create(:environment, project: project) }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('MetricsDashboard'.classify)}
    QUERY
  end

  let(:query) do
    %(
      query {
        project(fullPath:"#{project.full_path}") {
          environments(name: "#{environment.name}") {
            nodes {
              metricsDashboard(path: "#{path}"){
                #{fields}
              }
            }
          }
        }
      }
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
    before do
      project.add_developer(current_user)
      post_graphql(query, current_user: current_user)
    end

    context 'requested dashboard is available' do
      let(:path) { 'config/prometheus/common_metrics.yml' }

      it_behaves_like 'a working graphql query'

      it 'returns metrics dashboard' do
        dashboard = graphql_data.dig('project', 'environments', 'nodes')[0]['metricsDashboard']

        expect(dashboard).to eql("path" => path)
      end
    end

    context 'requested dashboard can not be found' do
      let(:path) { 'config/prometheus/i_am_not_here.yml' }

      it_behaves_like 'a working graphql query'

      it 'return snil' do
        dashboard = graphql_data.dig('project', 'environments', 'nodes')[0]['metricsDashboard']

        expect(dashboard).to be_nil
      end
    end
  end
end
