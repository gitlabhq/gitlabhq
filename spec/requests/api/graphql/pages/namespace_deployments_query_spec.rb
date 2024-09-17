# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespace Pages Deployments query', feature_category: :pages do
  include GraphqlHelpers

  let(:project_maintainer) { create(:user) }
  let(:user_namespace) { create(:user_namespace, owner: current_user, path: current_user.username) }
  let(:guest) { create(:user) }
  let!(:group) { create(:group) }
  let!(:projects) { create_list(:project, 2, { namespace: group }) }
  let!(:pages_deployments) do
    projects.flat_map do |project|
      [
        # primary deployment, still active
        create(:pages_deployment, project: project),
        # primary deployment, inactive
        create(:pages_deployment, project: project, deleted_at: Time.now - 2.hours),
        # versioned deployment, still active
        create(:pages_deployment, project: project, path_prefix: 'foo', expires_at: 1.day.from_now),
        # versioned deployment, inactive
        create(:pages_deployment, project: project, path_prefix: 'foo', deleted_at: Time.now - 2.hours)
      ]
    end
  end

  let(:fields) do
    <<~GRAPHQL
      pagesDeployments(#{pages_deployments_arguments}) {
        count
        pageInfo {
          endCursor
          hasNextPage
          hasPreviousPage
          startCursor
        }
        edges {
          cursor
          node {
            #{all_graphql_fields_for('PagesDeployment', max_depth: 2)}
          }
        }
      }
    GRAPHQL
  end

  let(:namespace_query_arguments) { { full_path: namespace_query } }
  let(:pages_deployments_arguments) { 'sort: CREATED_ASC, first: 10' }
  let(:query) { graphql_query_for('namespace', namespace_query_arguments, fields) }
  let(:deployments_response) do
    graphql_data_at(:namespace, :pages_deployments, :edges)
  end

  def fields_for_deployment(deployment, project = nil)
    {
      'id' => deployment.to_global_id.to_s,
      'active' => deployment.active?,
      'ciBuildId' => anything,
      'createdAt' => deployment.created_at.iso8601,
      'deletedAt' => deployment.deleted_at&.iso8601,
      'fileCount' => deployment.file_count,
      'pathPrefix' => deployment.path_prefix,
      'project' => project.nil? ? instance_of(Hash) : hash_including({ 'name' => project.name }),
      'rootDirectory' => deployment.root_directory,
      'size' => deployment.size,
      'updatedAt' => deployment.updated_at.iso8601,
      'expiresAt' => deployment.expires_at&.iso8601,
      'url' => deployment.url
    }
  end

  def match_deployment_node_for(deployment, project = nil)
    expect(deployments_response.first).to match({
      'cursor' => instance_of(String),
      'node' => fields_for_deployment(deployment, project)
    })
  end

  before do
    projects.each { |p| p.add_maintainer(project_maintainer) }
    post_graphql(query, current_user: current_user)
  end

  context 'when namespace is a group' do
    let(:namespace_query) { group.full_path }

    describe 'user is authorized' do
      let(:current_user) { project_maintainer }
      let(:expected_deployment) { pages_deployments[0] }
      let(:expected_project) { projects[0] }

      describe 'response' do
        it 'returns a deployment with all of the expected fields' do
          match_deployment_node_for(expected_deployment, expected_project)
        end
      end

      describe 'default connection fields' do
        let(:pages_deployments_arguments) { 'first: 5' }
        let!(:pages_deployments) do
          projects.flat_map do |project|
            create_list(:pages_deployment, 5, { project: project })
          end
        end

        it 'has all expected connection pagination fields' do
          expect(
            graphql_data_at(:namespace, :pages_deployments)
          ).to match(hash_including({
            'count' => 10,
            'pageInfo' => {
              'endCursor' => instance_of(String),
              'hasNextPage' => true,
              'hasPreviousPage' => false,
              'startCursor' => instance_of(String)
            }
          }))
        end
      end

      describe 'sorting' do
        let(:pages_deployments_arguments) { 'sort: CREATED_DESC' }
        let(:expected_deployment) { pages_deployments[pages_deployments.length - 1] }

        it 'returns the expected deployment' do
          match_deployment_node_for(expected_deployment)
        end
      end

      describe 'filtering' do
        describe 'active deployments' do
          let(:pages_deployments_arguments) { 'active: true' }

          it 'only returns active deployments' do
            expect(graphql_data_at(:namespace, :pages_deployments, :edges)).to all(match({
              'cursor' => instance_of(String),
              'node' => hash_including({
                'active' => true
              })
            }))
          end
        end

        describe 'only inactive deployments' do
          let(:pages_deployments_arguments) { 'active: false' }

          it 'only returns inactive deployments' do
            expect(graphql_data_at(:namespace, :pages_deployments, :edges)).to all(match({
              'cursor' => instance_of(String),
              'node' => hash_including({
                'active' => false
              })
            }))
          end
        end

        describe 'versioned deployments' do
          let(:pages_deployments_arguments) { 'versioned: true' }

          it 'only returns versioned deployments' do
            expect(graphql_data_at(:namespace, :pages_deployments, :edges)).to all(match({
              'cursor' => instance_of(String),
              'node' => hash_including({
                'pathPrefix' => 'foo'
              })
            }))
          end
        end

        describe 'unversioned deployments' do
          let(:pages_deployments_arguments) { 'versioned: false' }

          it 'only returns unversioned deployments' do
            expect(graphql_data_at(:namespace, :pages_deployments, :edges)).to all(match({
              'cursor' => instance_of(String),
              'node' => hash_including({
                'pathPrefix' => nil
              })
            }))
          end
        end
      end
    end

    describe 'user is unauthorized' do
      let(:current_user) { guest }

      it 'returns an empty result' do
        expect(deployments_response).to match([])
      end
    end
  end

  context 'when namespace is a user' do
    let(:current_user) { project_maintainer }
    let(:projects) { create_list(:project, 2, { namespace: user_namespace }) }

    let(:namespace_query) { current_user.username }
    let(:expected_deployment) { pages_deployments[0] }
    let(:expected_project) { projects[0] }

    describe 'user has a pages deployment' do
      it 'returns the expected result' do
        match_deployment_node_for(expected_deployment, expected_project)
      end
    end
  end
end
