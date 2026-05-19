# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'container repository tag details', feature_category: :container_registry do
  include_context 'container registry tags'
  include_context 'container registry client stubs'

  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be_with_reload(:container_repository) { create(:container_repository, project: project) }

  let(:tag_name) { 'latest' }
  let(:variables) { { id: container_repository.to_global_id.to_s, name: tag_name } }

  before do
    stub_container_registry_config(enabled: true)
    allow_next_instance_of(ContainerRegistry::Client) do |client|
      allow(client).to receive(:repository_tag_digest).and_return('sha256:digest')
    end
  end

  context 'for nested containerRepository { tagDetails } query' do
    let(:query) do
      <<~GQL
        query($id: ContainerRepositoryID!, $name: String!) {
          containerRepository(id: $id) {
            tagDetails(name: $name) {
              createdAt
              digest
              location
              manifests {
                digest
                mediaType
                platform {
                  os
                  architecture
                  variant
                  osVersion
                }
                size
              }
              mediaType
              name
              path
              platform {
                os
                architecture
                variant
                osVersion
              }
              publishedAt
              totalSize
            }
          }
        }
      GQL
    end

    let(:tag_response) { graphql_data.dig('containerRepository', 'tagDetails') }

    context 'with different permissions' do
      let_it_be(:user) { create(:user) }

      where(:project_visibility, :role, :access_granted) do
        :private | :maintainer | true
        :private | :developer  | true
        :private | :reporter   | true
        :private | :guest      | false
        :private | :anonymous  | false
        :public  | :maintainer | true
        :public  | :developer  | true
        :public  | :reporter   | true
        :public  | :guest      | true
        :public  | :anonymous  | true
      end

      with_them do
        before do
          project.update!(visibility_level: Gitlab::VisibilityLevel.const_get(project_visibility.to_s.upcase, false))
          project.add_member(user, role) unless role == :anonymous

          # tag details requires gitlab api support
          stub_container_registry_gitlab_api_support(supported: true) do |client|
            stub_container_registry_tag_details(client,
              path: container_repository.path, tag: tag_name, response: standard_oci_image_manifest_response)
          end
        end

        it 'returns the expected response' do
          post_graphql(query, current_user: user, variables: variables)

          if access_granted
            expect(tag_response).not_to be_nil
            expect(tag_response['name']).to eq(tag_name)
          else
            expect(tag_response).to be_nil
          end
        end
      end
    end

    context 'when user has access' do
      let(:user) { project.first_owner }

      context 'with an index tag' do
        before do
          stub_container_registry_gitlab_api_support(supported: true) do |client|
            stub_container_registry_tag_details(client,
              path: container_repository.path, tag: tag_name, response: standard_oci_image_index_response)
          end
        end

        it 'returns the tag with manifests' do
          post_graphql(query, current_user: user, variables: variables)
          expect(tag_response['createdAt']).to eq("2026-03-01T12:00:00+00:00")
          expect(tag_response['digest']).to eq("sha256:00000000")
          expect(tag_response['location']).to eq("#{container_repository.location}:#{tag_name}")
          expect(tag_response['mediaType']).to eq("application/vnd.oci.image.index.v1+json")
          expect(tag_response['name']).to eq(tag_name)
          expect(tag_response['path']).to eq("#{container_repository.path}:#{tag_name}")
          expect(tag_response['platform']).to be_nil
          expect(tag_response['publishedAt']).to eq("2026-03-01T15:00:00+00:00")
          expect(tag_response['totalSize']).to eq('0')

          expect(tag_response['manifests']).to be_an(Array)
          expect(tag_response['manifests'].size).to eq(3)
          expect(tag_response['manifests']).to match_array([
            {
              'digest' => 'sha256:11111111',
              'mediaType' => 'application/vnd.oci.image.manifest.v1+json',
              'platform' => { 'os' => 'linux', 'architecture' => 'amd64', 'variant' => nil, 'osVersion' => nil },
              'size' => '100'
            },
            {
              'digest' => 'sha256:22222222',
              'mediaType' => 'application/vnd.oci.image.manifest.v1+json',
              'platform' => { 'os' => 'linux', 'architecture' => 'arm64', 'variant' => 'v8', 'osVersion' => nil },
              'size' => '200'
            },
            {
              'digest' => 'sha256:33333333',
              'mediaType' => 'application/vnd.oci.image.manifest.v1+json',
              'platform' => {
                'os' => 'windows', 'architecture' => 'amd64', 'variant' => nil, 'osVersion' => '10.0.20348.4529'
              },
              'size' => '300'
            }
          ])
        end
      end

      context 'with an image tag' do
        before do
          stub_container_registry_gitlab_api_support(supported: true) do |client|
            stub_container_registry_tag_details(client,
              path: container_repository.path, tag: tag_name, response: standard_oci_image_manifest_response)
          end
        end

        it 'returns manifests as null' do
          post_graphql(query, current_user: user, variables: variables)

          expect(tag_response['createdAt']).to eq("2026-03-01T16:00:00+00:00")
          expect(tag_response['digest']).to eq("sha256:99999999")
          expect(tag_response['location']).to eq("#{container_repository.location}:#{tag_name}")
          expect(tag_response['manifests']).to be_nil
          expect(tag_response['mediaType']).to eq("application/vnd.oci.image.manifest.v1+json")
          expect(tag_response['name']).to eq(tag_name)
          expect(tag_response['path']).to eq("#{container_repository.path}:#{tag_name}")
          expect(tag_response['platform']).to include('architecture' => 'amd64', 'os' => 'linux')
          expect(tag_response['publishedAt']).to eq("2026-03-01T18:00:00+00:00")
          expect(tag_response['totalSize']).to eq('63624122')
        end
      end

      context 'when the tag does not exist' do
        before do
          stub_container_registry_gitlab_api_support(supported: true) do |client|
            stub_container_registry_tag_details(client,
              path: container_repository.path, tag: tag_name, response: nil)
          end
        end

        it 'returns null tagDetails with no errors' do
          post_graphql(query, current_user: user, variables: variables)

          expect(tag_response).to be_nil
          expect(graphql_errors).to be_nil
        end
      end
    end
  end
end
