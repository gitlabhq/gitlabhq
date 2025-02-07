# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CiJobTokenScopeAddGroupOrProject', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, ci_inbound_job_token_scope_enabled: true) }

  let(:policies) { %w[READ_CONTAINERS] }

  let(:mutation_response) { graphql_mutation_response(:ci_job_token_scope_add_group_or_project) }

  let(:variables) do
    {
      project_path: project.full_path,
      target_path: target_path.full_path,
      job_token_policies: policies
    }
  end

  let(:mutation) do
    graphql_mutation(:ci_job_token_scope_add_group_or_project, variables) do
      <<~QL
        errors
        ciJobTokenScope {
          groupsAllowlist {
            nodes {
              path
            }
          }
          inboundAllowlist {
            nodes {
              path
            }
          }
          inboundAllowlistCount
          groupsAllowlistCount
        }
        ciJobTokenScopeAllowlistEntry {
          sourceProject {
            fullPath
          }
          target {
            ... on CiJobTokenAccessibleProject {
              fullPath
            }
            ... on CiJobTokenAccessibleGroup {
              fullPath
            }
          }
          direction
          jobTokenPolicies
          addedBy {
            name
          }
          createdAt
        }
      QL
    end
  end

  shared_examples 'not authorized' do
    let_it_be(:current_user) { create(:user, developer_of: project) }

    context 'when not a maintainer' do
      it 'has graphql errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).not_to be_empty
      end
    end
  end

  shared_examples 'invalid target' do
    before do
      variables[:target_path] = 'unknown/project_or_group'
    end

    it 'has mutation errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['errors'])
      .to contain_exactly(::Ci::JobTokenScope::EditScopeValidations::TARGET_DOES_NOT_EXIST)
    end
  end

  context 'when we add a group' do
    let_it_be(:target_group) { create(:group, :private) }
    let(:target_path) { target_group }

    it_behaves_like 'not authorized'

    context 'when authorized' do
      let_it_be(:current_user) { create(:user, maintainer_of: project, guest_of: target_group) }

      it 'adds the target group to the job token scope', :aggregate_failures do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          expect(response).to have_gitlab_http_status(:success)

          created_link = Ci::JobToken::GroupScopeLink.last

          expect(mutation_response.dig('ciJobTokenScope', 'groupsAllowlist', 'nodes')).not_to be_empty
          expect(mutation_response.dig('ciJobTokenScope', 'groupsAllowlistCount')).to eq(1)
          expect(mutation_response.dig('ciJobTokenScope', 'inboundAllowlistCount')).to eq(1)

          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'sourceProject',
            'fullPath')).to eq(project.full_path)
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'target',
            'fullPath')).to eq(target_group.full_path)
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'direction')).to eq('inbound')
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'jobTokenPolicies')).to eq(policies)
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'addedBy', 'name')).to eq(current_user.name)
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry',
            'createdAt')).to eq(created_link.created_at.iso8601)
        end.to change { Ci::JobToken::GroupScopeLink.count }.by(1)
      end

      it_behaves_like 'invalid target'
    end
  end

  context 'when we add a project' do
    let_it_be(:target_project) { create(:project) }
    let(:target_path) { target_project }

    it_behaves_like 'not authorized'

    context 'when authorized' do
      let_it_be(:current_user) { create(:user, maintainer_of: project, guest_of: target_project) }

      it 'adds the target project to the job token scope', :aggregate_failures do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          expect(response).to have_gitlab_http_status(:success)

          created_link = Ci::JobToken::ProjectScopeLink.last

          expect(mutation_response.dig('ciJobTokenScope', 'inboundAllowlist', 'nodes')).not_to be_empty
          expect(mutation_response.dig('ciJobTokenScope', 'groupsAllowlistCount')).to eq(0)
          expect(mutation_response.dig('ciJobTokenScope', 'inboundAllowlistCount')).to eq(2)

          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'sourceProject',
            'fullPath')).to eq(project.full_path)
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'target',
            'fullPath')).to eq(target_project.full_path)
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'direction')).to eq('inbound')
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'jobTokenPolicies')).to eq(policies)
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry', 'addedBy', 'name')).to eq(current_user.name)
          expect(mutation_response.dig('ciJobTokenScopeAllowlistEntry',
            'createdAt')).to eq(created_link.created_at.iso8601)
        end.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)
      end

      it_behaves_like 'invalid target'
    end
  end
end
