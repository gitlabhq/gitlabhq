# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Environments query', feature_category: :continuous_delivery do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be_with_refind(:production) { create(:environment, :production, project: project) }
  let_it_be_with_refind(:staging) { create(:environment, :staging, project: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  subject { post_graphql(query, current_user: user) }

  let(:user) { developer }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          environment(name: "#{production.name}") {
            slug
            createdAt
            updatedAt
            autoStopAt
            autoDeleteAt
            tier
            environmentType
          }
        }
      }
    )
  end

  it 'returns the specified fields of the environment', :aggregate_failures do
    production.update!(auto_stop_at: 1.day.ago, auto_delete_at: 2.days.ago, environment_type: 'review')

    subject

    environment_data = graphql_data.dig('project', 'environment')
    expect(environment_data['slug']).to eq(production.slug)
    expect(environment_data['createdAt']).to eq(production.created_at.iso8601)
    expect(environment_data['updatedAt']).to eq(production.updated_at.iso8601)
    expect(environment_data['autoStopAt']).to eq(production.auto_stop_at.iso8601)
    expect(environment_data['autoDeleteAt']).to eq(production.auto_delete_at.iso8601)
    expect(environment_data['tier']).to eq(production.tier.upcase)
    expect(environment_data['environmentType']).to eq(production.environment_type)
  end

  context 'with cluster agent' do
    let_it_be(:agent_management_project) { create(:project, :private, :repository) }
    let_it_be(:cluster_agent) { create(:cluster_agent, project: agent_management_project) }

    let_it_be(:deployment_project) { create(:project, :private, :repository) }
    let_it_be(:environment) { create(:environment, project: deployment_project, cluster_agent: cluster_agent) }

    let!(:authorization) do
      create(:agent_user_access_project_authorization, project: deployment_project, agent: cluster_agent)
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{deployment_project.full_path}") {
            environment(name: "#{environment.name}") {
              clusterAgent {
                name
              }
            }
          }
        }
      )
    end

    before_all do
      deployment_project.add_developer(developer)
    end

    it 'returns the cluster agent of the environment' do
      subject

      cluster_agent_data = graphql_data.dig('project', 'environment', 'clusterAgent')
      expect(cluster_agent_data['name']).to eq(cluster_agent.name)
    end

    context 'when the cluster is not authorized in the project' do
      let!(:authorization) { nil }

      it 'does not return the cluster agent of the environment' do
        subject

        cluster_agent_data = graphql_data.dig('project', 'environment', 'clusterAgent')
        expect(cluster_agent_data).to be_nil
      end
    end
  end

  describe 'user permissions' do
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            environment(name: "#{production.name}") {
              userPermissions {
                updateEnvironment
                destroyEnvironment
                stopEnvironment
              }
            }
          }
        }
      )
    end

    it 'returns user permissions of the environment', :aggregate_failures do
      subject

      permission_data = graphql_data.dig('project', 'environment', 'userPermissions')
      expect(permission_data['updateEnvironment']).to eq(true)
      expect(permission_data['destroyEnvironment']).to eq(false)
      expect(permission_data['stopEnvironment']).to eq(true)
    end

    context 'when fetching user permissions for multiple environments' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environments {
                nodes {
                  userPermissions {
                    updateEnvironment
                    destroyEnvironment
                    stopEnvironment
                  }
                }
              }
            }
          }
        )
      end

      it 'limits the result', :aggregate_failures do
        subject

        expect_graphql_errors_to_include('"userPermissions" field can be requested only ' \
                                         'for 1 Environment(s) at a time.')
      end
    end
  end

  describe 'last deployments of environments' do
    ::Deployment.statuses.each_key do |status| # rubocop:disable RSpec/UselessDynamicDefinition -- `status` used in `let_it_be`
      let_it_be(:"production_#{status}_deployment") do
        create(:deployment, status.to_sym, environment: production, project: project)
      end

      let_it_be(:"staging_#{status}_deployment") do
        create(:deployment, status.to_sym, environment: staging, project: project)
      end
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            environments {
              nodes {
                name
                lastSuccessDeployment: lastDeployment(status: SUCCESS) {
                  iid
                }
                lastRunningDeployment: lastDeployment(status: RUNNING) {
                  iid
                }
                lastBlockedDeployment: lastDeployment(status: BLOCKED) {
                  iid
                }
              }
            }
          }
        }
      )
    end

    it 'returns all last deployments of the environment' do
      subject

      environments_data = graphql_data_at(:project, :environments, :nodes)

      environments_data.each do |environment_data|
        name = environment_data['name']
        success_deployment = public_send(:"#{name}_success_deployment")
        running_deployment = public_send(:"#{name}_running_deployment")
        blocked_deployment = public_send(:"#{name}_blocked_deployment")

        expect(environment_data['lastSuccessDeployment']['iid']).to eq(success_deployment.iid.to_s)
        expect(environment_data['lastRunningDeployment']['iid']).to eq(running_deployment.iid.to_s)
        expect(environment_data['lastBlockedDeployment']['iid']).to eq(blocked_deployment.iid.to_s)
      end
    end

    it 'executes the same number of queries in single environment and multiple environments' do
      single_environment_query =
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              environment(name: "#{production.name}") {
                name
                lastSuccessDeployment: lastDeployment(status: SUCCESS) {
                  iid
                }
                lastRunningDeployment: lastDeployment(status: RUNNING) {
                  iid
                }
                lastBlockedDeployment: lastDeployment(status: BLOCKED) {
                  iid
                }
              }
            }
          }
        )

      baseline = ActiveRecord::QueryRecorder.new do
        run_with_clean_state(single_environment_query, context: { current_user: user })
      end

      multi = ActiveRecord::QueryRecorder.new do
        run_with_clean_state(query, context: { current_user: user })
      end

      expect(multi).not_to exceed_query_limit(baseline)
    end
  end

  describe 'nested environments' do
    let_it_be(:testing1) { create(:environment, name: 'testing/one', project: project) }
    let_it_be(:testing2) { create(:environment, name: 'testing/two', project: project) }

    context 'with query' do
      let(:query) do
        %(
        query {
          project(fullPath: "#{project.full_path}") {
            nestedEnvironments {
              nodes {
                name
                size
                environment {
                  name
                  path
                }
              }
            }
          }
        }
      )
      end

      it 'can fetch nested environments' do
        subject

        nested_envs = graphql_data.dig('project', 'nestedEnvironments', 'nodes')
        expect(nested_envs.count).to be(3)
        expect(nested_envs.pluck('name')).to match_array(%w[production staging testing])
        expect(nested_envs.pluck('size')).to match_array([1, 1, 2])
        expect(nested_envs[0].dig('environment', 'name')).to eq(production.name)
      end

      context 'when user is guest' do
        let(:user) { create(:user, guest_of: project) }

        it 'returns nothing' do
          subject

          nested_envs = graphql_data.dig('project', 'nestedEnvironments', 'nodes')

          expect(nested_envs).to be_nil
        end
      end
    end

    context 'when using pagination' do
      let(:query) do
        %(
        query {
          project(fullPath: "#{project.full_path}") {
            nestedEnvironments(first: 1) {
              nodes {
                name
              }
              pageInfo {
                hasPreviousPage
                startCursor
                endCursor
                hasNextPage
              }
            }
          }
        }
      )
      end

      it 'supports pagination' do
        subject
        nested_envs = graphql_data.dig('project', 'nestedEnvironments')
        expect(nested_envs['nodes'].count).to eq(1)
        expect(nested_envs.dig('pageInfo', 'hasNextPage')).to be_truthy
      end
    end
  end
end
