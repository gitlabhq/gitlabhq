# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CiJobTokenScopeRemoveProject', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:target_project) { create(:project) }

  let_it_be(:link) do
    create(:ci_job_token_project_scope_link,
      source_project: project,
      target_project: target_project,
      direction: 'inbound'
    )
  end

  let(:variables) do
    {
      direction: 'INBOUND',
      project_path: project.full_path,
      target_project_path: target_project.full_path
    }
  end

  let(:mutation) do
    graphql_mutation(:ci_job_token_scope_remove_project, variables) do
      <<~QL
        errors
        ciJobTokenScope {
          projects {
            nodes {
              path
            }
          }
        }
        ciJobTokenScopeAllowlistEntry {
          sourceProject {
            fullPath
          }
          target {
            ... on CiJobTokenAccessibleProject {
              fullPath
            }
          }
          direction
          createdAt
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:ci_job_token_scope_remove_project) }

  context 'when unauthorized' do
    let(:current_user) { create(:user, developer_of: project) }

    context 'when not a maintainer' do
      it 'has graphql errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end

  context 'when authorized' do
    let_it_be(:current_user) { create(:user, maintainer_of: project, guest_of: target_project) }

    it 'removes the target project from the job token scope', :aggregate_failures do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        expect(response).to have_gitlab_http_status(:success)

        expect(mutation_response.dig('ciJobTokenScope', 'projects', 'nodes')).not_to be_empty

        expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'sourceProject', 'fullPath')).to eq(project.full_path)
        expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'target', 'fullPath')).to eq(target_project.full_path)
        expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'direction')).to eq('inbound')
        expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'createdAt')).to eq(link.created_at.iso8601)
      end.to change { Ci::JobToken::ProjectScopeLink.count }.by(-1)
    end

    context 'when invalid target project is provided' do
      before do
        variables[:target_project_path] = 'unknown/project'
      end

      it 'has mutation errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to contain_exactly(Ci::JobTokenScope::EditScopeValidations::TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND)
      end
    end
  end
end
