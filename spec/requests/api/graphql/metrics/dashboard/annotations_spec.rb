# frozen_string_literal: true

require 'spec_helper'

describe 'Getting Metrics Dashboard Annotations' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:path) { 'config/prometheus/common_metrics.yml' }
  let_it_be(:from) { "2020-04-01T03:29:25Z" }
  let_it_be(:to) { Time.zone.now.advance(minutes: 5) }
  let_it_be(:annotation) { create(:metrics_dashboard_annotation, environment: environment, dashboard_path: path) }
  let_it_be(:annotation_for_different_env) { create(:metrics_dashboard_annotation, dashboard_path: path) }
  let_it_be(:annotation_for_different_dashboard) { create(:metrics_dashboard_annotation, environment: environment, dashboard_path: ".gitlab/dashboards/test.yml") }
  let_it_be(:to_old_annotation) do
    create(:metrics_dashboard_annotation, environment: environment, starting_at: Time.parse(from).advance(minutes: -5), dashboard_path: path)
  end
  let_it_be(:to_new_annotation) do
    create(:metrics_dashboard_annotation, environment: environment, starting_at: to.advance(minutes: 5), dashboard_path: path)
  end

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('MetricsDashboardAnnotation'.classify)}
    QUERY
  end

  let(:query) do
    %(
          query {
            project(fullPath:"#{project.full_path}") {
              environments(name: "#{environment.name}") {
                nodes {
                  metricsDashboard(path: "#{path}"){
                    annotations(#{args}){
                      nodes {
                        #{fields}
                      }
                    }
                  }
                }
              }
            }
          }
        )
  end

  context 'feature flag metrics_dashboard_annotations' do
    let(:args) { "from: \"#{from}\", to: \"#{to}\"" }

    before do
      project.add_developer(current_user)
    end

    context 'is off' do
      before do
        stub_feature_flags(metrics_dashboard_annotations: false)
        post_graphql(query, current_user: current_user)
      end

      it 'returns empty nodes array' do
        annotations = graphql_data.dig('project', 'environments', 'nodes')[0].dig('metricsDashboard', 'annotations', 'nodes')

        expect(annotations).to be_empty
      end
    end

    context 'is on' do
      before do
        stub_feature_flags(metrics_dashboard_annotations: true)
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns annotations' do
        annotations = graphql_data.dig('project', 'environments', 'nodes')[0].dig('metricsDashboard', 'annotations', 'nodes')

        expect(annotations).to match_array [{
                                              "description" => annotation.description,
                                              "id" => annotation.to_global_id.to_s,
                                              "panelId" => annotation.panel_xid,
                                              "startingAt" => annotation.starting_at.to_s,
                                              "endingAt" => nil
                                            }]
      end

      context 'arguments' do
        context 'from is missing' do
          let(:args) { "to: \"#{from}\"" }

          it 'returns error' do
            post_graphql(query, current_user: current_user)

            expect(graphql_errors[0]).to include("message" => "Field 'annotations' is missing required arguments: from")
          end
        end

        context 'to is missing' do
          let(:args) { "from: \"#{from}\"" }

          it_behaves_like 'a working graphql query'
        end
      end
    end
  end
end
