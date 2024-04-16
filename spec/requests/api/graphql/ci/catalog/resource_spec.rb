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

  let_it_be_with_reload(:resource) { create(:ci_catalog_resource, :published, project: project) }

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
          fullPath: project.full_path,
          webPath: "/#{project.full_path}",
          verificationLevel: "UNVERIFIED",
          starCount: project.star_count
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
    let_it_be(:version) do
      create(:release, :with_catalog_resource_version, project: project).catalog_resource_version
    end

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

    let_it_be(:components) do
      create_list(
        :ci_catalog_resource_component, 2, version: version, spec: { inputs: inputs }
      )
    end

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
                    includePath
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

    it 'returns the components' do
      post_query

      expect(graphql_data_at(:ciCatalogResource)).to match(a_graphql_entity_for(resource))

      expect(graphql_data_at(:ciCatalogResource, :versions, :nodes, :components, :nodes)).to contain_exactly(
        a_graphql_entity_for(
          components.first,
          name: components.first.name,
          include_path: components.first.include_path,
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
          include_path: components.last.include_path
        )
      )
    end
  end

  describe 'version fields' do
    before_all do
      # To test the readme_html field, we need to create versions with real commit shas
      project.repository.create_branch('branch_v2', project.default_branch)
      project.repository.update_file(
        user, 'README.md', 'Readme v2', message: 'Update readme', branch_name: 'branch_v2')

      project.repository.add_tag(user, '1.0.0', project.default_branch)
      project.repository.add_tag(user, '2.0.0', 'branch_v2')
    end

    let_it_be(:version1) do
      version = create(:release, :with_catalog_resource_version,
        project: project,
        tag: '1.0.0',
        sha: project.commit('1.0.0').sha,
        released_at: Date.yesterday
      ).catalog_resource_version

      version.update!(semver: '1.0.0')

      version
    end

    let_it_be(:version2) do
      version = create(:release, :with_catalog_resource_version,
        project: project,
        tag: '2.0.0',
        sha: project.commit('2.0.0').sha,
        released_at: Date.today
      ).catalog_resource_version

      version.update!(semver: '2.0.0')

      version
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
                  name
                  path
                  releasedAt
                }
              }
            }
          }
        GQL
      end

      it 'returns the resource with the versions data' do
        post_query

        expect(graphql_data_at(:ciCatalogResource)).to match(
          a_graphql_entity_for(resource)
        )

        expect(graphql_data_at(:ciCatalogResource, :versions, :nodes)).to contain_exactly(
          a_graphql_entity_for(
            version1,
            name: version1.name,
            path: project_tag_path(project, version1.name),
            releasedAt: version1.released_at
          ),
          a_graphql_entity_for(
            version2,
            name: version2.name,
            path: project_tag_path(project, version2.name),
            releasedAt: version2.released_at
          )
        )
      end

      context 'when the readmeHtml field is requested on more than one version' do
        let(:query) do
          <<~GQL
            query {
              ciCatalogResource(fullPath: "#{resource.project.full_path}") {
                versions {
                  nodes {
                    readmeHtml
                  }
                }
              }
            }
          GQL
        end

        it 'limits the request to 1 version at a time' do
          post_query

          expect_graphql_errors_to_include \
            [/"readmeHtml" field can be requested only for 1 CiCatalogResourceVersion\(s\) at a time./]
        end
      end

      context 'when the name argument is provided' do
        let(:name) { '1.0.0' }

        let(:query) do
          <<~GQL
            query {
              ciCatalogResource(fullPath: "#{resource.project.full_path}") {
                versions(name: "#{name}") {
                  nodes {
                    id
                    name
                    path
                    releasedAt
                    readmeHtml
                  }
                }
              }
            }
          GQL
        end

        it 'returns the version that matches the name' do
          post_query

          expect(graphql_data_at(:ciCatalogResource, :versions, :nodes)).to contain_exactly(
            a_graphql_entity_for(
              version1,
              name: version1.name,
              path: project_tag_path(project, version1.name),
              releasedAt: version1.released_at,
              readmeHtml: a_string_including(
                "#{project.full_path}/-/blob/#{project.default_branch}/README.md"
              )
            )
          )
        end

        context 'when no version matches the name' do
          let(:name) { 'does_not_exist' }

          it 'returns an empty array' do
            post_query

            expect(graphql_data_at(:ciCatalogResource, :versions, :nodes)).to eq([])
          end
        end
      end

      context 'when the resource does not have a version' do
        it 'returns an empty array' do
          resource.versions.delete_all(:delete_all)

          post_query

          expect(graphql_data_at(:ciCatalogResource, :versions, :nodes)).to eq([])
        end
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
