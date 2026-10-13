# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciCatalogResources', feature_category: :pipeline_composition do
  include GraphqlHelpers

  using RSpec::Parameterized::TableSyntax

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

  let_it_be_with_reload(:public_project) do
    create(
      :project, :with_avatar, :custom_repo, :public,
      name: 'Public Component',
      description: 'A public component',
      files: { 'README.md' => '**Test**' }
    )
  end

  let_it_be_with_reload(:private_resource) do
    create(:ci_catalog_resource, :published, project: private_project, latest_released_at: '2023-01-01T00:00:00Z',
      last_30_day_usage_count: 15)
  end

  let_it_be_with_reload(:public_resource) { create(:ci_catalog_resource, :published, project: public_project) }

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
      end.not_to exceed_query_limit(control_count).allow_skip_cache_inconsistency
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
    let_it_be_with_reload(:private_resource_v1) do
      create(:ci_catalog_resource_version, semver: '1.0.0', catalog_resource: private_resource)
    end

    let_it_be_with_reload(:private_resource_v2) do
      create(:ci_catalog_resource_version, semver: '2.0.0', catalog_resource: private_resource)
    end

    let_it_be_with_reload(:public_resource_v1) do
      create(:ci_catalog_resource_version, semver: '1.0.0', catalog_resource: public_resource)
    end

    let_it_be_with_reload(:public_resource_v2) do
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

    context 'when the project repository feature is enabled' do
      let(:query) do
        <<~GQL
          query {
            ciCatalogResources {
              nodes {
                id
                versions(first: 1) {
                  nodes {
                    id
                    readme
                  }
                }
              }
            }
          }
        GQL
      end

      it 'resolves the readme field for versions' do
        post_query

        resources = graphql_data_at(:ciCatalogResources, :nodes)
        versions = resources.flat_map { |r| r.dig('versions', 'nodes') }

        expect(versions).to all(have_key('readme'))
      end
    end

    context 'when the project repository feature is disabled' do
      let(:query) do
        <<~GQL
          query {
            ciCatalogResources {
              nodes {
                id
                versions(first: 1) {
                  nodes {
                    id
                    readme
                    readmeHtml
                  }
                }
              }
            }
          }
        GQL
      end

      before do
        public_project.project_feature.update!(
          repository_access_level: ProjectFeature::DISABLED,
          merge_requests_access_level: ProjectFeature::DISABLED,
          builds_access_level: ProjectFeature::DISABLED
        )
      end

      it 'returns null for readme and readmeHtml fields on the affected resource' do
        post_query

        resources = graphql_data_at(:ciCatalogResources, :nodes)

        public_resource_data = resources.find { |r| r['id'] == public_resource.to_global_id.to_s }
        public_versions = public_resource_data.dig('versions', 'nodes')

        public_versions.each do |version|
          expect(version['readme']).to be_nil
          expect(version['readmeHtml']).to be_nil
        end
      end
    end

    context 'when querying version paths' do
      let(:query) do
        <<~GQL
          query {
            ciCatalogResources {
              nodes {
                fullPath
                versions(first: 1) {
                  nodes {
                    id
                    path
                  }
                }
                webPath
              }
            }
          }
        GQL
      end

      it 'avoids N+1 queries when accessing project namespace routes', :request_store, :use_sql_query_cache do
        ctx = { current_user: user }

        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          run_with_clean_state(query, context: ctx)
        end

        new_namespace = create(:group, developers: user)
        new_project = create(:project, namespace: new_namespace)
        new_resource = create(:ci_catalog_resource, :published, project: new_project)
        create(:ci_catalog_resource_version, semver: '1.0.0', catalog_resource: new_resource)

        expect do
          run_with_clean_state(query, context: ctx)
        end.not_to exceed_query_limit(control).allow_skip_cache_inconsistency
      end
    end
  end

  describe 'the catalog list page query' do
    let(:query) { get_graphql_query_as_string('ci/catalog/graphql/queries/get_ci_catalog_resources.query.graphql') }

    def create_resource_with_versions(version_count)
      group = create(:group, developers: user)
      project = create(:project, :public, namespace: group)
      resource = create(:ci_catalog_resource, :published, project: project)

      version_count.times do |i|
        version = create(:ci_catalog_resource_version, catalog_resource: resource, semver: "1.#{i}.0")
        create(:ci_catalog_resource_component, version: version)
      end
    end

    it 'avoids N+1 queries as resources and versions are added' do
      create_resource_with_versions(1)

      ctx = { current_user: user }

      run_with_clean_state(query, context: ctx)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        run_with_clean_state(query, context: ctx)
      end

      2.times { create_resource_with_versions(3) }

      expect do
        run_with_clean_state(query, context: ctx)
      end.to issue_same_number_of_queries_as(control)
    end

    it 'loads only the versions the page shows' do
      2.times { create_resource_with_versions(3) }

      loaded = 0
      callback = ->(*, payload) do
        loaded += payload[:record_count] if payload[:class_name] == Ci::Catalog::Resources::Version.name
      end

      ActiveSupport::Notifications.subscribed(callback, 'instantiation.active_record') do
        run_with_clean_state(query, context: { current_user: user })
      end

      expect(loaded).to eq(4)
    end
  end

  describe 'versions pagination' do
    let_it_be(:paginated_resource, freeze: false) do
      create(:ci_catalog_resource, :published, project: create(:project, :public, namespace: namespace))
    end

    let_it_be(:paginated_versions) do
      %w[1.0.0 2.0.0 3.0.0].map do |semver|
        create(:ci_catalog_resource_version, catalog_resource: paginated_resource, semver: semver)
      end
    end

    def versions_for(versions_args, selection)
      query = graphql_query_for(:ciCatalogResources, {}, <<~GQL)
        nodes { id versions(#{versions_args}) { #{selection} } }
      GQL

      result = run_with_clean_state(query, context: { current_user: user }).to_h
      node = result.dig('data', 'ciCatalogResources', 'nodes').find do |resource|
        resource['id'] == paginated_resource.to_global_id.to_s
      end

      node['versions']
    end

    it 'returns the highest version and reports the next page' do
      versions = versions_for('first: 1', 'pageInfo { hasNextPage endCursor } nodes { name }')

      expect(versions['nodes']).to eq([{ 'name' => '3.0.0' }])
      expect(versions.dig('pageInfo', 'hasNextPage')).to be(true)
    end

    it 'counts every version' do
      expect(versions_for('first: 1', 'count')).to eq({ 'count' => 3 })
    end

    it 'returns the next page after a cursor' do
      cursor = versions_for('first: 2', 'pageInfo { endCursor }').dig('pageInfo', 'endCursor')

      versions = versions_for("first: 1, after: \"#{cursor}\"", 'nodes { name }')

      expect(versions['nodes']).to eq([{ 'name' => '1.0.0' }])
    end

    where(:first, :limit) do
      5000 | 101
      -5   | 1
    end

    with_them do
      it 'keeps the per-resource limit within the page size' do
        expect(Ci::Catalog::Resources::Version).to receive(:versions_for_catalog_resources)
          .with(anything, limit: limit).and_call_original

        versions_for("first: #{first}", 'nodes { name }')
      end
    end
  end
end
