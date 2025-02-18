# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying CI_JOB_TOKEN allowlist for a project', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private) }

  let_it_be(:target_project_1) { create(:project, :private) }
  let_it_be(:target_project_2) { create(:project, :private) }

  let_it_be(:target_group_1) { create(:group, :private) }
  let_it_be(:target_group_2) { create(:group, :private) }

  let_it_be(:current_user) { create(:user) }

  let(:query) do
    <<~QUERY
      query {
        project(fullPath: "#{project.full_path}") {
          id
          ciJobTokenScopeAllowlist {
            groupsAllowlist {
              nodes {
                sourceProject {
                  fullPath
                }
                target {
                  ... on CiJobTokenAccessibleGroup {
                    fullPath
                  }
                }
                addedBy {
                  username
                }
                defaultPermissions
                jobTokenPolicies
                direction
              }
              count
            }
            projectsAllowlist {
              nodes {
                sourceProject {
                  fullPath
                }
                target {
                  ... on CiJobTokenAccessibleProject {
                    fullPath
                  }
                }
                addedBy {
                  username
                }
                defaultPermissions
                jobTokenPolicies
                direction
              }
              count
            }
          }
        }
      }
    QUERY
  end

  let(:expected_groups_allowlist) do
    {
      'count' => 1,
      'nodes' => [
        {
          'addedBy' => { 'username' => current_user.username },
          'direction' => 'inbound',
          'defaultPermissions' => false,
          'jobTokenPolicies' => ['READ_CONTAINERS'],
          'sourceProject' => { 'fullPath' => project.full_path },
          'target' => { 'fullPath' => target_group_1.full_path }
        }
      ]
    }
  end

  let(:expected_projects_allowlist) do
    {
      'count' => 2,
      'nodes' => [
        {
          'addedBy' => { 'username' => current_user.username },
          'direction' => 'outbound',
          'defaultPermissions' => false,
          'jobTokenPolicies' => ['READ_CONTAINERS'],
          'sourceProject' => { 'fullPath' => project.full_path },
          'target' => { 'fullPath' => target_project_2.full_path }
        },
        {
          'addedBy' => { 'username' => current_user.username },
          'direction' => 'inbound',
          'defaultPermissions' => false,
          'jobTokenPolicies' => ['READ_CONTAINERS'],
          'sourceProject' => { 'fullPath' => project.full_path },
          'target' => { 'fullPath' => target_project_1.full_path }
        }
      ]
    }
  end

  subject(:allowlist) { graphql_data_at(:project, :ci_job_token_scope_allowlist) }

  context 'when user is not logged in' do
    let(:current_user) { nil }

    it 'returns an empty response' do
      post_graphql(query, current_user: current_user)

      expect(allowlist).to be_nil
    end
  end

  context 'when user is logged in' do
    context 'when user does not have access to query CI job token scopes for a project' do
      before_all do
        project.add_developer(current_user)
      end

      it 'returns false' do
        post_graphql(query, current_user: current_user)

        expect(allowlist).to be_nil
      end
    end

    context 'when user has access to query CI job token scopes for a project' do
      before_all do
        project.add_maintainer(current_user)

        target_project_1.add_guest(current_user)
        target_project_2.add_guest(current_user)
        target_group_1.add_guest(current_user)
        target_group_2.add_guest(current_user)

        create(
          :ci_job_token_project_scope_link,
          source_project: project,
          target_project: target_project_1,
          default_permissions: false,
          job_token_policies: %w[read_containers],
          added_by: current_user,
          direction: :inbound
        )

        create(
          :ci_job_token_project_scope_link,
          source_project: project,
          target_project: target_project_2,
          default_permissions: false,
          job_token_policies: %w[read_containers],
          added_by: current_user,
          direction: :outbound
        )

        create(
          :ci_job_token_group_scope_link,
          source_project: project,
          target_group: target_group_1,
          added_by: current_user,
          default_permissions: false,
          job_token_policies: %w[read_containers]
        )
      end

      it 'returns the correct data' do
        post_graphql(query, current_user: current_user)

        expect(allowlist['groupsAllowlist']).to eq(expected_groups_allowlist)
        expect(allowlist['projectsAllowlist']).to eq(expected_projects_allowlist)
      end

      context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
        before do
          stub_feature_flags(add_policies_to_ci_job_token: false)
        end

        it 'returns job token policies as null', :aggregate_failures do
          post_graphql(query, current_user: current_user)

          expect(allowlist.dig('groupsAllowlist', 'nodes', 0, 'jobTokenPolicies')).to be_nil
          expect(allowlist.dig('projectsAllowlist', 'nodes', 0, 'jobTokenPolicies')).to be_nil
          expect(allowlist.dig('projectsAllowlist', 'nodes', 1, 'jobTokenPolicies')).to be_nil
        end

        it 'returns default permissions as true', :aggregate_failures do
          post_graphql(query, current_user: current_user)

          expect(allowlist.dig('groupsAllowlist', 'nodes', 0, 'defaultPermissions')).to be(true)
          expect(allowlist.dig('projectsAllowlist', 'nodes', 0, 'defaultPermissions')).to be(true)
          expect(allowlist.dig('projectsAllowlist', 'nodes', 1, 'defaultPermissions')).to be(true)
        end
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        create(
          :ci_job_token_project_scope_link,
          source_project: project,
          target_project: target_project_2,
          direction: :inbound
        )

        create(
          :ci_job_token_group_scope_link,
          source_project: project,
          target_group: target_group_2
        )

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
      end
    end
  end
end
