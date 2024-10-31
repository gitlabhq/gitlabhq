# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Fetching Job Token Auth Logs for project allowlist', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:current_project) { create(:project) }

  let(:fetched_job_token_auth_logs_data) { graphql_data.dig('project', 'ciJobTokenAuthLogs') }
  let(:query) do
    %(
      query {
        project(fullPath: "#{current_project.full_path}") {
          ciJobTokenAuthLogs {
            nodes {
              lastAuthorizedAt
              originProject {
                fullPath
              }
            }
          }
        }
      }
    )
  end

  describe 'Get job token auth logs' do
    context 'with access to scope' do
      before do
        current_project.add_member(current_user, :maintainer)
      end

      context 'when no logs on project' do
        before do
          post_graphql(query, current_user: current_user)
        end

        it_behaves_like 'a working graphql query'

        it 'returns an empty logs list' do
          post_graphql(query, current_user: current_user)

          expect(fetched_job_token_auth_logs_data['nodes']).to be_empty
        end
      end

      context 'when accessed projects are in the logs' do
        let_it_be(:origin_project_one) { create(:project) }
        let_it_be(:origin_project_two) { create(:project) }
        let_it_be(:authorization_one) do
          create(:ci_job_token_authorization,
            origin_project: origin_project_one,
            accessed_project: current_project)
        end

        let_it_be(:authorization_two) do
          create(:ci_job_token_authorization,
            origin_project: origin_project_two,
            accessed_project: current_project)
        end

        before do
          origin_project_one.add_member(current_user, :maintainer)
          origin_project_two.add_member(current_user, :maintainer)

          post_graphql(query, current_user: current_user)
        end

        it 'gets authorized projects' do
          fetched_project_paths = fetched_job_token_auth_logs_data['nodes'].pluck('originProject').pluck('fullPath')

          expect(fetched_project_paths).to match_array([origin_project_one.full_path, origin_project_two.full_path])
        end
      end
    end

    context 'without access to scope' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns an empty result' do
        expect(fetched_job_token_auth_logs_data).to be_nil
      end
    end
  end
end
