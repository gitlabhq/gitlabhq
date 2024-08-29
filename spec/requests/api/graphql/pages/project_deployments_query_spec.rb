# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Pages Deployments query', feature_category: :pages do
  include GraphqlHelpers

  let_it_be(:project_maintainer) { create(:user) }
  let_it_be(:project_developer) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: project_maintainer, developers: project_developer) }
  let_it_be(:pages_deployments) do
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

  let(:query) do
    <<~GRAPHQL
      query GetProjectWithPagesDeployments {
        project(fullPath: "#{project.full_path}") {
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
                #{all_graphql_fields_for('PagesDeployment', max_depth: 1)}
              }
            }
          }
        }
      }
    GRAPHQL
  end

  let(:pages_deployments_arguments) { 'sort: CREATED_ASC, first: 10' }
  let(:deployments_response) do
    graphql_data_at(:project, :pages_deployments, :edges)
  end

  def fields_for_deployment(deployment)
    {
      'id' => deployment.to_global_id.to_s,
      'active' => deployment.active?,
      'ciBuildId' => anything,
      'createdAt' => deployment.created_at.iso8601,
      'deletedAt' => deployment.deleted_at&.iso8601,
      'fileCount' => deployment.file_count,
      'pathPrefix' => deployment.path_prefix,
      'rootDirectory' => deployment.root_directory,
      'size' => deployment.size,
      'updatedAt' => deployment.updated_at.iso8601,
      'expiresAt' => deployment.expires_at&.iso8601,
      'url' => deployment.url
    }
  end

  def match_deployment_node_for(deployment)
    expect(deployments_response.first).to match({
      'cursor' => instance_of(String),
      'node' => fields_for_deployment(deployment)
    })
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  describe 'user is authorized' do
    let(:current_user) { project_maintainer }
    let(:expected_deployment) { pages_deployments[0] }

    describe 'response' do
      it 'returns a deployment with all of the expected fields' do
        match_deployment_node_for(expected_deployment)
      end
    end

    describe 'default connection fields' do
      let(:pages_deployments_arguments) { 'first: 3' }

      it 'has all expected connection pagination fields' do
        expect(
          graphql_data_at(:project, :pages_deployments)
        ).to match(hash_including({
          'count' => 4,
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
          expect(graphql_data_at(:project, :pages_deployments, :edges)).to all(match({
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
          expect(graphql_data_at(:project, :pages_deployments, :edges)).to all(match({
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
          expect(graphql_data_at(:project, :pages_deployments, :edges)).to all(match({
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
          expect(graphql_data_at(:project, :pages_deployments, :edges)).to all(match({
            'cursor' => instance_of(String),
            'node' => hash_including({
              'pathPrefix' => nil
            })
          }))
        end
      end
    end

    describe 'user is unauthorized to view pages deployments' do
      let(:current_user) { project_developer }

      it 'returns an empty result' do
        expect(deployments_response).to match([])
      end
    end
  end
end
