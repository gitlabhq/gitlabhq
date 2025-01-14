# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciCatalogResources', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group, developers: user) }
  let_it_be(:project) { create(:project, namespace: namespace) }

  let_it_be(:private_project) do
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

  let_it_be(:private_resource) do
    create(:ci_catalog_resource, :published, project: private_project, latest_released_at: '2023-01-01T00:00:00Z',
      last_30_day_usage_count: 15)
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
            visibilityLevel
            latestReleasedAt
            starCount
            starrersPath
            last30DayUsageCount
            topics
          }
        }
      }
    GQL
  end

  subject(:post_query) { post_graphql(query, current_user: user) }

  shared_examples 'avoids N+1 queries' do
    it do
      ctx = { current_user: user }

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        run_with_clean_state(query, context: ctx)
      end

      create(:ci_catalog_resource, :published, project: project)

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
        private_resource, :name, :description,
        icon: private_project.avatar_path,
        latestReleasedAt: private_resource.latest_released_at,
        starCount: private_project.star_count,
        starrersPath: Gitlab::Routing.url_helpers.project_starrers_path(private_project),
        verificationLevel: 'UNVERIFIED',
        visibilityLevel: 'private',
        fullPath: private_project.full_path,
        webPath: "/#{private_project.full_path}",
        last30DayUsageCount: private_resource.last_30_day_usage_count
      ),
      a_graphql_entity_for(public_resource, visibilityLevel: 'public')
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

  describe 'catalog resources topics' do
    it 'returns array if there are no topics set' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:ciCatalogResources, :nodes, :topics)).to match([])
    end

    it 'returns topics' do
      public_resource.project.update!(topic_list: 'topic1, topic2, topic3')

      post_graphql(query, current_user: user)

      expect(graphql_data_at(:ciCatalogResources, :nodes, :topics)).to match(%w[topic1 topic2 topic3])
    end
  end

  describe 'versions' do
    let!(:private_resource_v1) do
      create(:ci_catalog_resource_version, semver: '1.0.0', catalog_resource: private_resource)
    end

    let!(:private_resource_v2) do
      create(:ci_catalog_resource_version, semver: '2.0.0', catalog_resource: private_resource)
    end

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
          private_resource,
          versions: {
            'nodes' => [
              a_graphql_entity_for(private_resource_v2),
              a_graphql_entity_for(private_resource_v1)
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
end
