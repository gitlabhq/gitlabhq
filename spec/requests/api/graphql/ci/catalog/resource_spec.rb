# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciCatalogResource', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }

  let_it_be(:project) do
    create(
      :project, :with_avatar, :custom_repo,
      name: 'Component Repository',
      description: 'A simple component',
      namespace: namespace,
      star_count: 1,
      files: {
        'README.md' => '[link](README.md)',
        'templates/secret-detection.yml' => "spec:\n inputs:\n  website:\n---\nimage: alpine_1"
      }
    )
  end

  let_it_be(:resource) { create(:ci_catalog_resource, :published, project: project) }

  let(:query) do
    <<~GQL
      query {
        ciCatalogResource(id: "#{resource.to_global_id}") {
          #{all_graphql_fields_for('CiCatalogResource', max_depth: 1)}
        }
      }
    GQL
  end

  subject(:post_query) { post_graphql(query, current_user: user) }

  before_all do
    namespace.add_developer(user)
  end

  context 'when the current user has permission to read the namespace catalog' do
    it 'returns the resource with the expected data' do
      post_query

      expect(graphql_data_at(:ciCatalogResource)).to match(
        a_graphql_entity_for(
          resource, :name, :description,
          icon: project.avatar_path,
          webPath: "/#{project.full_path}",
          starCount: project.star_count,
          readmeHtml: a_string_including(
            "#{project.full_path}/-/blob/#{project.default_branch}/README.md"
          )
        )
      )
    end
  end

  context 'when the current user does not have permission to read the namespace catalog' do
    it 'returns nil' do
      namespace.add_guest(user)

      post_query

      expect(graphql_data_at(:ciCatalogResource)).to be_nil
    end
  end

  describe 'components' do
    let(:query) do
      <<~GQL
        query {
          ciCatalogResource(id: "#{resource.to_global_id}") {
            id
            versions {
              nodes {
                id
                components {
                  nodes {
                    id
                    name
                    path
                    inputs {
                      name
                      default
                      required
                    }
                  }
                }
              }
            }
          }
        }
      GQL
    end

    context 'when the catalog resource has components' do
      let_it_be(:inputs) do
        {
          website: nil,
          environment: {
            default: 'test'
          },
          tags: {
            type: 'array'
          }
        }
      end

      let_it_be(:version) do
        create(:release, :with_catalog_resource_version, project: project).catalog_resource_version
      end

      let_it_be(:components) do
        create_list(:ci_catalog_resource_component, 2, version: version, inputs: inputs, path: 'templates/comp.yml')
      end

      it 'returns the resource with the component data' do
        post_query

        expect(graphql_data_at(:ciCatalogResource)).to match(a_graphql_entity_for(resource))

        expect(graphql_data_at(:ciCatalogResource, :versions, :nodes, :components, :nodes)).to contain_exactly(
          a_graphql_entity_for(
            components.first,
            name: components.first.name,
            path: components.first.path,
            inputs: [
              a_graphql_entity_for(
                name: 'tags',
                default: nil,
                required: true
              ),
              a_graphql_entity_for(
                name: 'website',
                default: nil,
                required: true
              ),
              a_graphql_entity_for(
                name: 'environment',
                default: 'test',
                required: false
              )
            ]
          ),
          a_graphql_entity_for(
            components.last,
            name: components.last.name,
            path: components.last.path
          )
        )
      end
    end
  end

  describe 'versions' do
    let(:query) do
      <<~GQL
        query {
          ciCatalogResource(id: "#{resource.to_global_id}") {
            id
            versions {
              nodes {
                id
                tagName
                tagPath
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
      let_it_be(:author) { create(:user, name: 'author') }

      let_it_be(:version1) do
        create(:release, :with_catalog_resource_version, project: project, released_at: '2023-01-01T00:00:00Z',
          author: author).catalog_resource_version
      end

      let_it_be(:version2) do
        create(:release, :with_catalog_resource_version, project: project, released_at: '2023-02-01T00:00:00Z',
          author: author).catalog_resource_version
      end

      it 'returns the resource with the versions data' do
        post_query

        expect(graphql_data_at(:ciCatalogResource)).to match(
          a_graphql_entity_for(resource)
        )

        expect(graphql_data_at(:ciCatalogResource, :versions, :nodes)).to contain_exactly(
          a_graphql_entity_for(
            version1,
            tagName: version1.name,
            tagPath: project_tag_path(project, version1.name),
            releasedAt: version1.released_at,
            author: a_graphql_entity_for(author, :name)
          ),
          a_graphql_entity_for(
            version2,
            tagName: version2.name,
            tagPath: project_tag_path(project, version2.name),
            releasedAt: version2.released_at,
            author: a_graphql_entity_for(author, :name)
          )
        )
      end
    end

    context 'when the resource does not have a version' do
      it 'returns versions as an empty array' do
        post_query

        expect(graphql_data_at(:ciCatalogResource)).to match(
          a_graphql_entity_for(resource, versions: { 'nodes' => [] })
        )
      end
    end
  end

  describe 'latestVersion' do
    let(:query) do
      <<~GQL
        query {
          ciCatalogResource(id: "#{resource.to_global_id}") {
            id
            latestVersion {
              id
              tagName
              tagPath
              releasedAt
              author {
                id
                name
                webUrl
              }
            }
          }
        }
      GQL
    end

    context 'when the resource has versions' do
      let_it_be(:author) { create(:user, name: 'author') }

      let_it_be(:latest_version) do
        create(:release, :with_catalog_resource_version, project: project, released_at: '2023-02-01T00:00:00Z',
          author: author).catalog_resource_version
      end

      before_all do
        # Previous version of the catalog resource
        create(:release, :with_catalog_resource_version, project: project, released_at: '2023-01-01T00:00:00Z',
          author: author)
      end

      it 'returns the resource with the latest version data' do
        post_query

        expect(graphql_data_at(:ciCatalogResource)).to match(
          a_graphql_entity_for(
            resource,
            latestVersion: a_graphql_entity_for(
              latest_version,
              tagName: latest_version.name,
              tagPath: project_tag_path(project, latest_version.name),
              releasedAt: latest_version.released_at,
              author: a_graphql_entity_for(author, :name)
            )
          )
        )
      end
    end

    context 'when the resource does not have a version' do
      it 'returns nil' do
        post_query

        expect(graphql_data_at(:ciCatalogResource)).to match(
          a_graphql_entity_for(resource, latestVersion: nil)
        )
      end
    end
  end

  describe 'openIssuesCount' do
    context 'when open_issue_count is requested' do
      let(:query) do
        <<~GQL
          query {
            ciCatalogResource(id: "#{resource.to_global_id}") {
              openIssuesCount
            }
          }
        GQL
      end

      it 'returns the correct count' do
        create(:issue, :opened, project: project)
        create(:issue, :opened, project: project)

        post_query

        expect(graphql_data_at(:ciCatalogResource)).to match(
          a_graphql_entity_for(
            open_issues_count: 2
          )
        )
      end

      context 'when open_issue_count is zero' do
        it 'returns zero' do
          post_query

          expect(graphql_data_at(:ciCatalogResource)).to match(
            a_graphql_entity_for(
              open_issues_count: 0
            )
          )
        end
      end
    end
  end

  describe 'openMergeRequestsCount' do
    context 'when merge_requests_count is requested' do
      let(:query) do
        <<~GQL
          query {
            ciCatalogResource(id: "#{resource.to_global_id}") {
              openMergeRequestsCount
            }
          }
        GQL
      end

      it 'returns the correct count' do
        create(:merge_request, :opened, source_project: project)

        post_query

        expect(graphql_data_at(:ciCatalogResource)).to match(
          a_graphql_entity_for(
            open_merge_requests_count: 1
          )
        )
      end

      context 'when open merge_requests_count is zero' do
        it 'returns zero' do
          post_query

          expect(graphql_data_at(:ciCatalogResource)).to match(
            a_graphql_entity_for(
              open_merge_requests_count: 0
            )
          )
        end
      end
    end
  end
end
