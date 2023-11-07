# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'query Jira projects', feature_category: :integrations do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  include_context 'Jira projects request context'

  let(:services) { graphql_data_at(:project, :services, :edges) }
  let(:jira_projects) { services.first.dig('node', 'projects', 'nodes') }
  let(:projects_query) { 'projects' }
  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          services(active: true, type: JIRA_SERVICE) {
            edges {
              node {
                ... on JiraService {
                  %{projects_query} {
                    nodes {
                      key
                      name
                      projectId
                    }
                  }
                }
              }
            }
          }
        }
      }
    ) % { projects_query: projects_query }
  end

  context 'when user does not have access' do
    it_behaves_like 'unauthorized users cannot read services'
  end

  context 'when user can access project services' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'retuns list of jira projects' do
      project_keys = jira_projects.map { |jp| jp['key'] }
      project_names = jira_projects.map { |jp| jp['name'] }
      project_ids = jira_projects.map { |jp| jp['projectId'] }

      expect(jira_projects.size).to eq(2)
      expect(project_keys).to eq(%w[EX ABC])
      expect(project_names).to eq(%w[Example Alphabetical])
      expect(project_ids).to eq([10000, 10001])
    end

    context 'with pagination' do
      context 'when fetching limited number of projects' do
        shared_examples_for 'fetches first project' do
          it 'retuns first project from list of fetched projects' do
            project_keys = jira_projects.map { |jp| jp['key'] }
            project_names = jira_projects.map { |jp| jp['name'] }
            project_ids = jira_projects.map { |jp| jp['projectId'] }

            expect(jira_projects.size).to eq(1)
            expect(project_keys).to eq(%w[EX])
            expect(project_names).to eq(%w[Example])
            expect(project_ids).to eq([10000])
          end
        end

        context 'without cursor' do
          let(:projects_query) { 'projects(first: 1)' }

          it_behaves_like 'fetches first project'
        end
      end
    end
  end
end
