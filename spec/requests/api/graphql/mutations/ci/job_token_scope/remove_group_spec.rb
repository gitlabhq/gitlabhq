# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CiJobTokenScopeRemoveGroup', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, ci_inbound_job_token_scope_enabled: true) }

  let_it_be(:target_group) { create(:group, :private) }

  let_it_be(:link) do
    create(:ci_job_token_group_scope_link,
      source_project: project,
      target_group: target_group
    )
  end

  let(:variables) do
    {
      project_path: project.full_path,
      target_group_path: target_group.full_path
    }
  end

  let(:mutation) do
    graphql_mutation(:ci_job_token_scope_remove_group, variables) do
      <<~QL
        errors
        ciJobTokenScope {
          groupsAllowlist {
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
            ... on CiJobTokenAccessibleGroup {
              fullPath
            }
          }
          createdAt
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:ci_job_token_scope_remove_group) }

  context 'when unauthorized' do
    let_it_be(:current_user) { create(:user, developer_of: project) }

    context 'when not a maintainer' do
      it 'has graphql errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end

  context 'when authorized' do
    let_it_be(:current_user) { create(:user, maintainer_of: project, guest_of: target_group) }

    it 'removes the target group from the job token scope', :aggregate_failures do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        expect(response).to have_gitlab_http_status(:success)

        expect(mutation_response.dig('ciJobTokenScope', 'groupsAllowlist', 'nodes')).to be_empty

        expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'sourceProject',
          'fullPath')).to eq(project.full_path)
        expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'target',
          'fullPath')).to eq(target_group.full_path)
        expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'createdAt')).to eq(link.created_at.iso8601)
      end.to change { Ci::JobToken::GroupScopeLink.count }.by(-1)
    end

    context 'when invalid target group is provided' do
      before do
        variables[:target_group_path] = 'unknown/project'
      end

      it 'has mutation errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors'])
        .to contain_exactly('Target group is not in the job token scope')
      end
    end
  end
end
