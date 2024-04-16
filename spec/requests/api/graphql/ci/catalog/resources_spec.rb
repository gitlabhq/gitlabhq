# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciCatalogResources', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project2) { create(:project, namespace: namespace) }

  let_it_be(:project1) do
    create(
      :project, :with_avatar, :custom_repo,
      name: 'Component Repository',
      description: 'A simple component',
      namespace: namespace,
      star_count: 1,
      files: { 'README.md' => '**Test**' }
    )
  end

  let_it_be(:public_project) do
    create(
      :project, :with_avatar, :custom_repo, :public,
      name: 'Public Component',
      description: 'A public component',
      files: { 'README.md' => '**Test**' }
    )
  end

  let_it_be(:resource1) do
    create(:ci_catalog_resource, :published, project: project1, latest_released_at: '2023-01-01T00:00:00Z')
  end

  let_it_be(:public_resource) { create(:ci_catalog_resource, :published, project: public_project) }

  let(:query) do
    <<~GQL
      query {
        ciCatalogResources {
          nodes {
            id
            name
            description
            icon
            fullPath
            webPath
            verificationLevel
            latestReleasedAt
            starCount
            starrersPath
          }
        }
      }
    GQL
  end

  subject(:post_query) { post_graphql(query, current_user: user) }

  before_all do
    namespace.add_developer(user)
  end

  shared_examples 'avoids N+1 queries' do
    it do
      ctx = { current_user: user }

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        run_with_clean_state(query, context: ctx)
      end

      create(:ci_catalog_resource, :published, project: project2)

      expect do
        run_with_clean_state(query, context: ctx)
      end.not_to exceed_query_limit(control_count)
    end
  end

  it_behaves_like 'avoids N+1 queries'

  it 'returns the resources with the expected data' do
    post_query

    expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
      a_graphql_entity_for(
        resource1, :name, :description,
        icon: project1.avatar_path,
        latestReleasedAt: resource1.latest_released_at,
        starCount: project1.star_count,
        starrersPath: Gitlab::Routing.url_helpers.project_starrers_path(project1),
        verificationLevel: 'UNVERIFIED',
        fullPath: project1.full_path,
        webPath: "/#{project1.full_path}"
      ),
      a_graphql_entity_for(public_resource)
    )
  end

  describe 'with an unauthorized user on a private project' do
    let_it_be(:query) do
      <<~GQL
        query {
          ciCatalogResources {
            nodes {
              id
              versions {
                nodes {
                  id
                  name
                }
              }
            }
          }
        }
      GQL
    end

    it 'returns only the public data' do
      post_graphql(query, current_user: create(:user))

      expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
        a_graphql_entity_for(public_resource)
      )
    end
  end

  describe 'versions' do
    let!(:resource1_v1) { create(:ci_catalog_resource_version, semver: '1.0.0', catalog_resource: resource1) }
    let!(:resource1_v2) { create(:ci_catalog_resource_version, semver: '2.0.0', catalog_resource: resource1) }
    let!(:public_resource_v1) do
      create(:ci_catalog_resource_version, semver: '1.0.0', catalog_resource: public_resource)
    end

    let!(:public_resource_v2) do
      create(:ci_catalog_resource_version, semver: '2.0.0', catalog_resource: public_resource)
    end

    let(:query) do
      <<~GQL
        query {
          ciCatalogResources {
            nodes {
              id
              versions {
                nodes {
                  id
                  name
                  releasedAt
                  author {
                    id
                    name
                    webUrl
                  }
                }
              }
            }
          }
        }
      GQL
    end

    it 'returns versions for the catalog resources ordered by semver' do
      post_query

      expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
        a_graphql_entity_for(
          resource1,
          versions: {
            'nodes' => [
              a_graphql_entity_for(resource1_v2),
              a_graphql_entity_for(resource1_v1)
            ]
          }
        ),
        a_graphql_entity_for(
          public_resource,
          versions: {
            'nodes' => [
              a_graphql_entity_for(public_resource_v2),
              a_graphql_entity_for(public_resource_v1)
            ]
          }
        )
      )
    end

    it_behaves_like 'avoids N+1 queries'
  end

  describe 'openIssuesCount' do
    before_all do
      create(:issue, :opened, project: project1)
      create(:issue, :opened, project: project1)

      create(:issue, :opened, project: public_project)
    end

    let(:query) do
      <<~GQL
        query {
          ciCatalogResources {
            nodes {
              openIssuesCount
            }
          }
        }
      GQL
    end

    it 'returns the correct count' do
      post_query

      expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
        a_graphql_entity_for(openIssuesCount: 2),
        a_graphql_entity_for(openIssuesCount: 1)
      )
    end

    it_behaves_like 'avoids N+1 queries'
  end

  describe 'openMergeRequestsCount' do
    before_all do
      namespace.add_developer(user)
    end

    before_all do
      create(:merge_request, :opened, source_project: project1)
      create(:merge_request, :opened, source_project: public_project)
    end

    let(:query) do
      <<~GQL
        query {
          ciCatalogResources {
            nodes {
              openMergeRequestsCount
            }
          }
        }
      GQL
    end

    it 'returns the correct count' do
      post_query

      expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
        a_graphql_entity_for(openMergeRequestsCount: 1),
        a_graphql_entity_for(openMergeRequestsCount: 1)
      )
    end

    it_behaves_like 'avoids N+1 queries'
  end
end
