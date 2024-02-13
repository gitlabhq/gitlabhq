# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CiJobTokenScopeRemoveGroup', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) do
    create(:project,
      ci_inbound_job_token_scope_enabled: true
    )
  end

  let_it_be(:target_group) { create(:group, :private) }

  let_it_be(:link) do
    create(:ci_job_token_group_scope_link,
      source_project: project,
      target_group: target_group)
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
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:ci_job_token_scope_remove_group) }

  context 'when unauthorized' do
    let_it_be(:current_user) { create(:user) }

    context 'when not a maintainer' do
      before_all do
        project.add_developer(current_user)
      end

      it 'has graphql errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end

  context 'when authorized' do
    let_it_be(:current_user) { project.first_owner }

    before_all do
      target_group.add_guest(current_user)
    end

    it 'removes the target group from the job token scope' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response.dig('ciJobTokenScope', 'groupsAllowlist', 'nodes')).to be_empty
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
