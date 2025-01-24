# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'container repository details', feature_category: :container_registry do
  include_context 'container registry tags'
  include_context 'container registry client stubs'

  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be_with_reload(:container_repository) { create(:container_repository, project: project) }

  let(:variables) do
    { id: container_repository_global_id }
  end

  let(:query) do
    <<~GQL
      query($id: ContainerRepositoryID!) {
        containerRepository(id: $id) {
          #{all_graphql_fields_for('ContainerRepositoryDetails', max_depth: 1)}
          tags {
            nodes {
              #{all_graphql_fields_for('ContainerRepositoryTag', max_depth: 1)}
              userPermissions {
                destroyContainerRepositoryTag
              }
            }
          }
          userPermissions {
            destroyContainerRepository
          }
          project {
            id
          }
        }
      }
    GQL
  end

  let(:user) { project.first_owner }
  let(:tags) { %w[latest tag1 tag2 tag3 tag4 tag5] }
  let(:container_repository_global_id) { container_repository.to_global_id.to_s }
  let(:container_repository_details_response) { graphql_data['containerRepository'] }

  before do
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: container_repository.path, tags: tags, with_manifest: true)
  end

  subject { post_graphql(query, current_user: user, variables: variables) }

  shared_examples 'returning an invalid value error' do
    it 'returns an error' do
      subject

      expect(graphql_errors.first['message']).to match(/invalid value/)
    end
  end

  shared_examples 'returning proper responses with different permissions' do |raw_tags:|
    context 'with different permissions' do
      let_it_be(:user) { create(:user) }

      let(:repository_tags) { instance_exec(&raw_tags) }
      let(:tags_response) { container_repository_details_response.dig('tags', 'edges') }
      let(:variables) do
        { id: container_repository_global_id, n: 'NAME_ASC' }
      end

      let(:query) do
        <<~GQL
          query($id: ContainerRepositoryID!, $n: ContainerRepositoryTagSort) {
            containerRepository(id: $id) {
              userPermissions {
                destroyContainerRepository
              }
              tags(sort: $n) {
                edges {
                  node {
                    #{all_graphql_fields_for('ContainerRepositoryTag')}
                  }
                }
              }
            }
          }
        GQL
      end

      where(:project_visibility, :role, :access_granted, :destroy_container_repository) do
        :private | :maintainer | true  | true
        :private | :developer  | true  | true
        :private | :reporter   | true  | false
        :private | :guest      | false | false
        :private | :anonymous  | false | false
        :public  | :maintainer | true  | true
        :public  | :developer  | true  | true
        :public  | :reporter   | true  | false
        :public  | :guest      | true  | false
        :public  | :anonymous  | true  | false
      end

      with_them do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility.to_s.upcase, false))
          project.add_member(user, role) unless role == :anonymous
        end

        it 'return the proper response' do
          subject

          if access_granted
            expect(tags_response.size).to eq(repository_tags.size)
            expect(container_repository_details_response.dig('userPermissions', 'destroyContainerRepository')).to eq(destroy_container_repository)
          else
            expect(container_repository_details_response).to be_nil
          end
        end
      end
    end
  end

  it_behaves_like 'a working graphql query' do
    before do
      subject
    end

    it 'matches the JSON schema' do
      expect(container_repository_details_response).to match_schema('graphql/container_repository_details')
    end
  end

  context 'with a giant size tag' do
    let(:tags) { %w[latest] }
    let(:giant_size) { 1.terabyte }
    let(:tag_sizes_response) { graphql_data_at('containerRepository', 'tags', 'nodes', 'totalSize') }
    let(:fields) do
      <<~GQL
        tags {
          nodes {
            totalSize
          }
        }
      GQL
    end

    let(:query) do
      graphql_query_for(
        'containerRepository',
        { id: container_repository_global_id },
        fields
      )
    end

    it 'returns the expected value as a string' do
      stub_next_container_registry_tags_call(:total_size, giant_size)

      subject

      expect(tag_sizes_response.first).to eq(giant_size.to_s)
    end
  end

  context 'limiting the number of tags' do
    let(:limit) { 2 }
    let(:tags_response) { container_repository_details_response.dig('tags', 'edges') }
    let(:variables) do
      { id: container_repository_global_id, n: limit }
    end

    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!, $n: Int) {
          containerRepository(id: $id) {
            tags(first: $n) {
              edges {
                node {
                  #{all_graphql_fields_for('ContainerRepositoryTag')}
                }
              }
            }
          }
        }
      GQL
    end

    it 'only returns n tags' do
      subject

      expect(tags_response.size).to eq(limit)
    end
  end

  context 'sorting the tags' do
    let(:sort) { 'NAME_DESC' }
    let(:tags_response) { container_repository_details_response.dig('tags', 'edges') }
    let(:variables) do
      { id: container_repository_global_id, n: sort }
    end

    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!, $n: ContainerRepositoryTagSort) {
          containerRepository(id: $id) {
            tags(sort: $n) {
              edges {
                node {
                  #{all_graphql_fields_for('ContainerRepositoryTag')}
                }
              }
            }
          }
        }
      GQL
    end

    before do
      stub_container_registry_gitlab_api_support(supported: false)
    end

    it 'sorts the tags', :aggregate_failures do
      subject

      expect(tags_response.first.dig('node', 'name')).to eq('tag5')
      expect(tags_response.last.dig('node', 'name')).to eq('latest')
    end

    context 'invalid sort' do
      let(:sort) { 'FOO_ASC' }

      it_behaves_like 'returning an invalid value error'
    end
  end

  context 'filtering by name' do
    let(:name) { 'l' }
    let(:tags_response) { container_repository_details_response.dig('tags', 'edges') }
    let(:variables) do
      { id: container_repository_global_id, n: name }
    end

    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!, $n: String) {
          containerRepository(id: $id) {
            tags(name: $n) {
              edges {
                node {
                  #{all_graphql_fields_for('ContainerRepositoryTag')}
                }
              }
            }
          }
        }
      GQL
    end

    it 'sorts the tags', :aggregate_failures do
      subject

      expect(tags_response.size).to eq(1)
      expect(tags_response.first.dig('node', 'name')).to eq('latest')
    end

    context 'invalid filter' do
      let(:name) { 1 }

      it_behaves_like 'returning an invalid value error'
    end
  end

  context 'size field' do
    let(:size_response) { container_repository_details_response['size'] }
    let(:variables) do
      { id: container_repository_global_id }
    end

    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!) {
          containerRepository(id: $id) {
            size
          }
        }
      GQL
    end

    it 'returns the size' do
      stub_container_registry_gitlab_api_support(supported: true) do |client|
        stub_container_registry_gitlab_api_repository_details(client, path: container_repository.path, size_bytes: 12345, sizing: :self)
      end

      subject

      expect(size_response).to eq(12345)
    end

    context 'with a network error' do
      it 'returns an error' do
        stub_container_registry_gitlab_api_network_error

        subject

        expect_graphql_errors_to_include("Can't connect to the Container Registry. If this error persists, please review the troubleshooting documentation.")
      end
    end

    context 'when the GitLab API is not supported' do
      it 'returns nil' do
        stub_container_registry_gitlab_api_support(supported: false)

        subject

        expect(size_response).to be_nil
      end
    end
  end

  context 'lastPublishedAt field' do
    let(:last_published_at_response) { container_repository_details_response['lastPublishedAt'] }
    let(:variables) do
      { id: container_repository_global_id }
    end

    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!) {
          containerRepository(id: $id) {
            lastPublishedAt
          }
        }
      GQL
    end

    it 'returns the last_published_at' do
      stub_container_registry_gitlab_api_support(supported: true) do |client|
        stub_container_registry_gitlab_api_repository_details(
          client,
          path: container_repository.path,
          sizing: :self,
          last_published_at: '2024-04-30T06:07:36.225Z'
        )
      end

      subject

      expect(last_published_at_response).to eq('2024-04-30T06:07:36+00:00')
    end

    context 'when the GitLab API is not supported' do
      it 'returns nil' do
        stub_container_registry_gitlab_api_support(supported: false)

        subject

        expect(last_published_at_response).to be_nil
      end
    end

    context 'with a network error' do
      it 'returns an error' do
        stub_container_registry_gitlab_api_network_error

        subject

        expect_graphql_errors_to_include("Can't connect to the Container Registry. If this error persists, please review the troubleshooting documentation.")
      end
    end
  end

  context 'with tags with a manifest containing nil fields' do
    let(:tags_response) { container_repository_details_response.dig('tags', 'nodes') }
    let(:errors) { container_repository_details_response['errors'] }

    %i[digest revision short_revision total_size created_at].each do |nilable_field|
      it "returns a list of tags with a nil #{nilable_field}" do
        stub_next_container_registry_tags_call(nilable_field, nil)

        subject

        expect(tags_response.size).to eq(tags.size)
        expect(graphql_errors).to be_nil
      end
    end
  end

  it_behaves_like 'handling graphql network errors with the container registry'

  context 'when the Gitlab API is not supported' do
    before do
      stub_container_registry_gitlab_api_support(supported: false)
    end

    it_behaves_like 'returning proper responses with different permissions', raw_tags: -> { tags }
  end

  context 'when the Gitlab API is supported' do
    before do
      stub_container_registry_config(enabled: true)
      allow_next_instances_of(ContainerRegistry::GitlabApiClient, nil) do |client|
        allow(client).to receive(:supports_gitlab_api?).and_return(true)
        allow(client).to receive(:tags).and_return(response_body)
        stub_container_registry_gitlab_api_repository_details(client, path: container_repository.path, sizing: :self)
      end
    end

    let_it_be(:raw_tags_response) do
      [
        {
          name: 'latest',
          digest: 'sha256:1234567892',
          config_digest: 'sha256:3332132331',
          media_type: 'application/vnd.oci.image.manifest.v1+json',
          size_bytes: 1234567892,
          created_at: 10.minutes.ago,
          updated_at: 10.minutes.ago
        }
      ]
    end

    let_it_be(:url) { URI('/gitlab/v1/repositories/group1/proj1/tags/list/?before=tag1') }

    let_it_be(:response_body) do
      {
        pagination: { previous: { uri: url }, next: { uri: url } },
        response_body: ::Gitlab::Json.parse(raw_tags_response.to_json)
      }
    end

    it_behaves_like 'a working graphql query' do
      before do
        subject
      end

      it 'matches the JSON schema' do
        expect(container_repository_details_response).to match_schema('graphql/container_repository_details')
      end
    end

    it_behaves_like 'returning proper responses with different permissions', raw_tags: -> { raw_tags_response }

    context 'querying' do
      let(:name) { 'l' }
      let(:tags_response) { container_repository_details_response.dig('tags', 'edges') }
      let(:variables) do
        { id: container_repository_global_id, n: name }
      end

      let(:query) do
        <<~GQL
          query($id: ContainerRepositoryID!, $n: String) {
            containerRepository(id: $id) {
              tags(name: $n) {
                edges {
                  node {
                    #{all_graphql_fields_for('ContainerRepositoryTag')}
                  }
                }
              }
            }
          }
        GQL
      end

      it 'returns the tag response', :aggregate_failures do
        subject

        expect(tags_response.size).to eq(1)
        expect(tags_response.first.dig('node', 'name')).to eq('latest')
      end

      context 'invalid filter' do
        let(:name) { 1 }

        it_behaves_like 'returning an invalid value error'
      end

      context 'with referrers' do
        let(:tags_response) { container_repository_details_response.dig('tags', 'edges') }
        let(:raw_tags_response) do
          [
            {
              name: 'latest',
              digest: 'sha256:1234567892',
              config_digest: 'sha256:3332132331',
              media_type: 'application/vnd.oci.image.manifest.v1+json',
              size_bytes: 1234509876,
              created_at: 10.minutes.ago,
              updated_at: 10.minutes.ago,
              referrers: [
                {
                  artifactType: 'application/vnd.example+type',
                  digest: 'sha256:57d3be92c2f857566ecc7f9306a80021c0a7fa631e0ef5146957235aea859961'
                },
                {
                  artifactType: 'application/vnd.example+type+2',
                  digest: 'sha256:01db72e42d61b8d2183d53475814cce2bfb9c8a254e97539a852441979cd5c90'
                }
              ]
            },
            {
              name: 'latest',
              digest: 'sha256:1234567893',
              config_digest: 'sha256:3332132331',
              media_type: 'application/vnd.oci.image.manifest.v1+json',
              size_bytes: 1234509877,
              created_at: 9.minutes.ago,
              updated_at: 9.minutes.ago
            }
          ]
        end

        let(:query) do
          <<~GQL
            query($id: ContainerRepositoryID!, $n: String) {
              containerRepository(id: $id) {
                tags(name: $n, referrers: true) {
                  edges {
                    node {
                      #{all_graphql_fields_for('ContainerRepositoryTag')}
                    }
                  }
                }
              }
            }
          GQL
        end

        let(:url) { URI('/gitlab/v1/repositories/group1/proj1/tags/list/?before=tag1&referrers=true') }

        let(:response_body) do
          {
            pagination: { previous: { uri: url }, next: { uri: url } },
            response_body: ::Gitlab::Json.parse(raw_tags_response.to_json)
          }
        end

        it 'includes referrers in response' do
          subject

          refs = tags_response.map { |tag| tag.dig('node', 'referrers') }

          expect(refs.first.size).to eq(2)
          expect(refs.first.first).to include({
            'artifactType' => 'application/vnd.example+type',
            'digest' => 'sha256:57d3be92c2f857566ecc7f9306a80021c0a7fa631e0ef5146957235aea859961'
          })
          expect(refs.first.second).to include({
            'artifactType' => 'application/vnd.example+type+2',
            'digest' => 'sha256:01db72e42d61b8d2183d53475814cce2bfb9c8a254e97539a852441979cd5c90'
          })

          expect(refs.second).to be_empty
        end
      end
    end

    it_behaves_like 'handling graphql network errors with the container registry'
  end

  context 'manifest field' do
    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!, $n: String!) {
          containerRepository(id: $id) {
            manifest(reference: $n)
          }
        }
      GQL
    end

    let(:reference) { 'latest' }
    let(:manifest_response) { container_repository_details_response['manifest'] }
    let(:variables) do
      { id: container_repository_global_id, n: reference }
    end

    context 'without network error' do
      before do
        allow_next_instance_of(ContainerRegistry::Client) do |client|
          allow(client).to receive(:repository_manifest)
            .with(container_repository.path, reference)
            .and_return(manifest_content)
        end
      end

      context 'with existing manifest' do
        let(:manifest_content) do
          <<~JSON
          {
            "schemaVersion": 2,
            "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
            "config": {
              "mediaType": "application/octet-stream",
              "size": 1145,
              "digest": "sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac"
            },
            "layers": [
              {
                "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
                "size": 2319870,
                "digest": "sha256:420890c9e918b6668faaedd9000e220190f2493b0693ee563ebd7b4cc754a57d"
              }
            ]
          }
          JSON
        end

        it 'fetches manifest payload' do
          subject

          expect(manifest_response).to eq(manifest_content)
        end
      end

      context 'with nonexisting manifest' do
        let(:reference) { 'nonexistent' }
        let(:manifest_content) { nil }

        it 'returns null' do
          subject
          expect(manifest_response).to be_nil
        end
      end
    end

    context 'with a network error' do
      it 'returns an error' do
        stub_container_registry_network_error(client_method: :repository_manifest)

        subject

        expect_graphql_errors_to_include("Can't connect to the Container Registry. If this error persists, please review the troubleshooting documentation.")
      end
    end
  end

  context 'migration_state field' do
    let(:migration_state_response) { container_repository_details_response['migrationState'] }
    let(:variables) do
      { id: container_repository_global_id }
    end

    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!) {
          containerRepository(id: $id) {
            migrationState
          }
        }
      GQL
    end

    it 'returns an empty string' do
      subject

      expect(migration_state_response).to eq('')
    end
  end

  context 'protection field' do
    let(:raw_tags_response) { [{ name: 'latest', digest: 'sha256:123' }] }
    let(:response_body) { { response_body: ::Gitlab::Json.parse(raw_tags_response.to_json) } }

    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!) {
          containerRepository(id: $id) {
            tags(first: 5) {
              nodes {
                protection {
                  minimumAccessLevelForPush
                  minimumAccessLevelForDelete
                }
              }
            }
          }
        }
      GQL
    end

    let(:tag_permissions_response) do
      container_repository_details_response.dig('tags', 'nodes')[0]['protection']
    end

    before_all do
      create(
        :container_registry_protection_tag_rule,
        project: project,
        tag_name_pattern: 'latest',
        minimum_access_level_for_push: 'maintainer',
        minimum_access_level_for_delete: 'owner'
      )

      create(
        :container_registry_protection_tag_rule,
        project: project,
        tag_name_pattern: '.*',
        minimum_access_level_for_push: 'owner',
        minimum_access_level_for_delete: 'maintainer'
      )

      create(
        :container_registry_protection_tag_rule,
        project: project,
        tag_name_pattern: 'non-matching-pattern',
        minimum_access_level_for_push: 'admin',
        minimum_access_level_for_delete: 'admin'
      )
    end

    it 'returns the maximum access fields from the matching protection rules' do
      subject

      expect(tag_permissions_response).to eq(
        {
          'minimumAccessLevelForPush' => 'OWNER',
          'minimumAccessLevelForDelete' => 'OWNER'
        }
      )
    end

    context 'when the feature container_registry_protected_tags is disabled' do
      before do
        stub_feature_flags(container_registry_protected_tags: false)
      end

      it 'returns nil' do
        subject

        expect(tag_permissions_response).to be_nil
      end
    end
  end
end
