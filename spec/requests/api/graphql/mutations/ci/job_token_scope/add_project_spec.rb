# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CiJobTokenScopeAddProject' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:target_project) { create(:project) }

  let(:variables) do
    {
      project_path: project.full_path,
      target_project_path: target_project.full_path
    }
  end

  let(:mutation) do
    graphql_mutation(:ci_job_token_scope_add_project, variables) do
      <<~QL
        errors
        ciJobTokenScope {
          projects {
            nodes {
              path
            }
          }
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:ci_job_token_scope_add_project) }

  context 'when unauthorized' do
    let(:current_user) { create(:user) }

    context 'when not a maintainer' do
      before do
        project.add_developer(current_user)
      end

      it 'has graphql errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end

  context 'when authorized' do
    let_it_be(:current_user) { project.owner }

    before do
      target_project.add_developer(current_user)
    end

    it 'adds the target project to the job token scope' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response.dig('ciJobTokenScope', 'projects', 'nodes')).not_to be_empty
      end.to change { Ci::JobToken::Scope.new(project).includes?(target_project) }.from(false).to(true)
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
