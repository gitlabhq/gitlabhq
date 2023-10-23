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

  let_it_be(:resource1) { create(:ci_catalog_resource, project: project1, latest_released_at: '2023-01-01T00:00:00Z') }

  let(:query) do
    <<~GQL
      query {
        ciCatalogResources(projectPath: "#{project1.full_path}") {
          nodes {
            #{all_graphql_fields_for('CiCatalogResource', max_depth: 1)}
          }
        }
      }
    GQL
  end

  subject(:post_query) { post_graphql(query, current_user: user) }

  shared_examples 'avoids N+1 queries' do
    it do
      ctx = { current_user: user }

      control_count = ActiveRecord::QueryRecorder.new do
        run_with_clean_state(query, context: ctx)
      end

      create(:ci_catalog_resource, project: project2)

      expect do
        run_with_clean_state(query, context: ctx)
      end.not_to exceed_query_limit(control_count)
    end
  end

  context 'when the current user has permission to read the namespace catalog' do
    before_all do
      namespace.add_developer(user)
    end

    it 'returns the resource with the expected data' do
      post_query

      expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
        a_graphql_entity_for(
          resource1, :name, :description,
          icon: project1.avatar_path,
          webPath: "/#{project1.full_path}",
          starCount: project1.star_count,
          forksCount: project1.forks_count,
          readmeHtml: a_string_including('Test</strong>'),
          latestReleasedAt: resource1.latest_released_at
        )
      )
    end

    context 'when there are two resources visible to the current user in the namespace' do
      it 'returns both resources with the expected data' do
        resource2 = create(:ci_catalog_resource, project: project2)

        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(resource1),
          a_graphql_entity_for(
            resource2, :name, :description,
            icon: project2.avatar_path,
            webPath: "/#{project2.full_path}",
            starCount: project2.star_count,
            forksCount: project2.forks_count,
            readmeHtml: '',
            latestReleasedAt: resource2.latest_released_at
          )
        )
      end

      it_behaves_like 'avoids N+1 queries'
    end
  end

  context 'when the current user does not have permission to read the namespace catalog' do
    it 'returns no resources' do
      post_query

      expect(graphql_data_at(:ciCatalogResources, :nodes)).to be_empty
    end
  end

  describe 'versions' do
    before_all do
      namespace.add_developer(user)
    end

    before do
      stub_licensed_features(ci_namespace_catalog: true)
    end

    let(:query) do
      <<~GQL
        query {
          ciCatalogResources(projectPath: "#{project1.full_path}") {
            nodes {
              id
              versions {
                nodes {
                  id
                  tagName
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

    context 'when there is a single resource visible to the current user in the namespace' do
      context 'when the resource has versions' do
        let_it_be(:author) { create(:user, name: 'author') }

        let_it_be(:version1) do
          create(:release, project: project1, released_at: '2023-01-01T00:00:00Z', author: author)
        end

        let_it_be(:version2) do
          create(:release, project: project1, released_at: '2023-02-01T00:00:00Z', author: author)
        end

        it 'returns the resource with the versions data' do
          post_query

          expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
            a_graphql_entity_for(resource1)
          )

          expect(graphql_data_at(:ciCatalogResources, :nodes, 0, :versions, :nodes)).to contain_exactly(
            a_graphql_entity_for(
              version1,
              tagName: version1.tag,
              releasedAt: version1.released_at,
              author: a_graphql_entity_for(author, :name)
            ),
            a_graphql_entity_for(
              version2,
              tagName: version2.tag,
              releasedAt: version2.released_at,
              author: a_graphql_entity_for(author, :name)
            )
          )
        end
      end

      context 'when the resource does not have a version' do
        it 'returns versions as an empty array' do
          post_query

          expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
            a_graphql_entity_for(resource1, versions: { 'nodes' => [] })
          )
        end
      end
    end

    context 'when there are multiple resources visible to the current user in the namespace' do
      it 'limits the request to 1 resource at a time' do
        create(:ci_catalog_resource, project: project2)

        post_query

        expect_graphql_errors_to_include \
          [/"versions" field can be requested only for 1 CiCatalogResource\(s\) at a time./]
      end

      it_behaves_like 'avoids N+1 queries'
    end
  end

  describe 'latestVersion' do
    before_all do
      namespace.add_developer(user)
    end

    before do
      stub_licensed_features(ci_namespace_catalog: true)
    end

    let(:query) do
      <<~GQL
        query {
          ciCatalogResources(projectPath: "#{project1.full_path}") {
            nodes {
              id
              latestVersion {
                id
                tagName
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
      GQL
    end

    context 'when the resource has versions' do
      let_it_be(:author1) { create(:user, name: 'author1') }
      let_it_be(:author2) { create(:user, name: 'author2') }

      let_it_be(:latest_version1) do
        create(:release, project: project1, released_at: '2023-02-01T00:00:00Z', author: author1)
      end

      let_it_be(:latest_version2) do
        create(:release, project: project2, released_at: '2023-02-01T00:00:00Z', author: author2)
      end

      before_all do
        # Previous versions of the projects
        create(:release, project: project1, released_at: '2023-01-01T00:00:00Z', author: author1)
        create(:release, project: project2, released_at: '2023-01-01T00:00:00Z', author: author2)
      end

      it 'returns the resource with the latest version data' do
        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(
            resource1,
            latestVersion: a_graphql_entity_for(
              latest_version1,
              tagName: latest_version1.tag,
              releasedAt: latest_version1.released_at,
              author: a_graphql_entity_for(author1, :name)
            )
          )
        )
      end

      context 'when there are multiple resources visible to the current user in the namespace' do
        let_it_be(:project0) { create(:project, namespace: namespace) }
        let_it_be(:resource0) { create(:ci_catalog_resource, project: project0) }
        let_it_be(:author0) { create(:user, name: 'author0') }

        let_it_be(:version0) do
          create(:release, project: project0, released_at: '2023-01-01T00:00:00Z', author: author0)
        end

        it 'returns all resources with the latest version data' do
          resource2 = create(:ci_catalog_resource, project: project2)

          post_query

          expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
            a_graphql_entity_for(
              resource0,
              latestVersion: a_graphql_entity_for(
                version0,
                tagName: version0.tag,
                releasedAt: version0.released_at,
                author: a_graphql_entity_for(author0, :name)
              )
            ),
            a_graphql_entity_for(
              resource1,
              latestVersion: a_graphql_entity_for(
                latest_version1,
                tagName: latest_version1.tag,
                releasedAt: latest_version1.released_at,
                author: a_graphql_entity_for(author1, :name)
              )
            ),
            a_graphql_entity_for(
              resource2,
              latestVersion: a_graphql_entity_for(
                latest_version2,
                tagName: latest_version2.tag,
                releasedAt: latest_version2.released_at,
                author: a_graphql_entity_for(author2, :name)
              )
            )
          )
        end

        it_behaves_like 'avoids N+1 queries'
      end
    end

    context 'when the resource does not have a version' do
      it 'returns nil' do
        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(resource1, latestVersion: nil)
        )
      end
    end
  end

  describe 'rootNamespace' do
    before_all do
      namespace.add_developer(user)
    end

    before do
      stub_licensed_features(ci_namespace_catalog: true)
    end

    let(:query) do
      <<~GQL
        query {
          ciCatalogResources(projectPath: "#{project1.full_path}") {
            nodes {
              id
              rootNamespace {
                id
                name
                path
              }
            }
          }
        }
      GQL
    end

    it 'returns the correct root namespace data' do
      post_query

      expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
        a_graphql_entity_for(
          resource1,
          rootNamespace: a_graphql_entity_for(namespace, :name, :path)
        )
      )
    end

    shared_examples 'returns the correct root namespace for both resources' do
      it do
        resource2 = create(:ci_catalog_resource, project: project2)

        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(resource1, rootNamespace: a_graphql_entity_for(namespace)),
          a_graphql_entity_for(resource2, rootNamespace: a_graphql_entity_for(namespace2))
        )
      end
    end

    shared_examples 'when there are two resources visible to the current user' do
      it_behaves_like 'returns the correct root namespace for both resources'
      it_behaves_like 'avoids N+1 queries'

      context 'when a resource is within a nested namespace' do
        let_it_be(:nested_namespace) { create(:group, parent: namespace2) }
        let_it_be(:project2) { create(:project, namespace: nested_namespace) }

        it_behaves_like 'returns the correct root namespace for both resources'
        it_behaves_like 'avoids N+1 queries'
      end
    end

    context 'when there are multiple resources visible to the current user from the same root namespace' do
      let_it_be(:namespace2) { namespace }

      it_behaves_like 'when there are two resources visible to the current user'
    end

    # We expect the resources resolver will eventually support returning resources from multiple root namespaces.
    context 'when there are multiple resources visible to the current user from different root namespaces' do
      before do
        # In order to mock this scenario, we allow the resolver to return
        # all existing resources without scoping to a specific namespace.
        allow_next_instance_of(::Ci::Catalog::Listing) do |instance|
          allow(instance).to receive(:resources).and_return(::Ci::Catalog::Resource.includes(:project))
        end
      end

      # Make the current user an Admin so it has `:read_namespace` ability on all namespaces
      let_it_be(:user) { create(:admin) }

      let_it_be(:namespace2) { create(:group) }
      let_it_be(:project2) { create(:project, namespace: namespace2) }

      it_behaves_like 'when there are two resources visible to the current user'

      context 'when a resource is within a User namespace' do
        let_it_be(:namespace2) { create(:user).namespace }
        let_it_be(:project2) { create(:project, namespace: namespace2) }

        # A response containing any number of 'User' type root namespaces will always execute 1 extra
        # query than a response with only 'Group' type root namespaces. This is due to their different
        # policies. Here we preemptively create another resource with a 'User' type root namespace so
        # that the control_count in the N+1 test includes this extra query.
        let_it_be(:namespace3) { create(:user).namespace }
        let_it_be(:resource3) { create(:ci_catalog_resource, project: create(:project, namespace: namespace3)) }

        it 'returns the correct root namespace for all resources' do
          resource2 = create(:ci_catalog_resource, project: project2)

          post_query

          expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
            a_graphql_entity_for(resource1, rootNamespace: a_graphql_entity_for(namespace)),
            a_graphql_entity_for(resource2, rootNamespace: a_graphql_entity_for(namespace2)),
            a_graphql_entity_for(resource3, rootNamespace: a_graphql_entity_for(namespace3))
          )
        end

        it_behaves_like 'avoids N+1 queries'
      end
    end
  end

  describe 'openIssuesCount' do
    before_all do
      namespace.add_developer(user)
    end

    before do
      stub_licensed_features(ci_namespace_catalog: true)
    end

    context 'when open_issues_count is requested' do
      before_all do
        create(:issue, :opened, project: project1)
        create(:issue, :opened, project: project1)

        create(:issue, :opened, project: project2)
      end

      let(:query) do
        <<~GQL
          query {
            ciCatalogResources(projectPath: "#{project1.full_path}") {
              nodes {
                openIssuesCount
              }
            }
          }
        GQL
      end

      it 'returns the correct count' do
        create(:ci_catalog_resource, project: project2)

        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(
            openIssuesCount: 2),
          a_graphql_entity_for(
            openIssuesCount: 1)
        )
      end

      it_behaves_like 'avoids N+1 queries'
    end
  end

  describe 'openMergeRequestsCount' do
    before_all do
      namespace.add_developer(user)
    end

    before do
      stub_licensed_features(ci_namespace_catalog: true)
    end

    context 'when open_merge_requests_count is requested' do
      before_all do
        create(:merge_request, :opened, source_project: project1)
        create(:merge_request, :opened, source_project: project2)
      end

      let(:query) do
        <<~GQL
          query {
            ciCatalogResources(projectPath: "#{project1.full_path}") {
              nodes {
                openMergeRequestsCount
              }
            }
          }
        GQL
      end

      it 'returns the correct count' do
        create(:ci_catalog_resource, project: project2)

        post_query

        expect(graphql_data_at(:ciCatalogResources, :nodes)).to contain_exactly(
          a_graphql_entity_for(
            openMergeRequestsCount: 1),
          a_graphql_entity_for(
            openMergeRequestsCount: 1)
        )
      end

      it_behaves_like 'avoids N+1 queries'
    end
  end
end
