# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ContainerRepositories, feature_category: :container_registry do
  include_context 'container registry client stubs'

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:repository) { create(:container_repository, project: project) }

  let(:users) do
    {
      anonymous: nil,
      guest: guest,
      reporter: reporter
    }
  end

  let(:api_user) { reporter }

  before do
    project.add_reporter(reporter)
    project.add_guest(guest)

    stub_container_registry_config(enabled: true)
  end

  describe 'GET /registry/repositories/:id' do
    let(:url) { "/registry/repositories/#{repository.id}" }

    subject { get api(url, api_user) }

    it_behaves_like 'rejected container repository access', :guest, :forbidden
    it_behaves_like 'rejected container repository access', :anonymous, :unauthorized

    context 'for allowed user' do
      it 'returns a repository' do
        subject

        expect(json_response['id']).to eq(repository.id)
        expect(response.body).not_to include('tags')
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/repository')
      end

      context 'with a network error' do
        before do
          stub_container_registry_network_error(client_method: :repository_tags)
        end

        it 'returns a matching schema' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('registry/repository')
        end
      end

      context 'with tags param' do
        let(:url) { "/registry/repositories/#{repository.id}?tags=true" }

        before do
          stub_container_registry_tags(repository: repository.path, tags: %w[rootA latest], with_manifest: true)
        end

        shared_examples 'returning a repository and its tags' do
          it 'returns a repository and its tags' do
            subject

            expect(json_response['id']).to eq(repository.id)
            expect(response.body).to include('tags')
            expect(json_response['tags']).to eq(repository.tags.map do |tag|
              {
                "location" => tag.location,
                "name" => tag.name,
                "path" => tag.path
              }
            end)
          end
        end

        it_behaves_like 'returning a repository and its tags'

        context 'when the GitLab API is supported' do
          before do
            stub_container_registry_gitlab_api_support(supported: true) do |client|
              allow(client).to receive(:tags).and_return(response_body)
            end
          end

          context 'when the Gitlab API returns tags' do
            include_context 'with the container registry GitLab API returning tags'

            it 'returns instantiated tags from the response' do
              expect_any_instance_of(ContainerRepository) do |repository|
                expect(repository).to receive(:each_tags_page).and_call_original
              end

              subject

              expect(json_response['id']).to eq(repository.id)
              expect(response.body).to include('tags')
              expect(json_response['tags'].count).to eq(2)
              expect(json_response['tags']).to eq(tags_response.map do |response|
                {
                  "name" => response[:name],
                  "path" => "#{repository.path}:#{response[:name]}",
                  "location" => "#{repository.location}:#{response[:name]}"
                }
              end)
            end
          end

          context 'when the Gitlab API does not return any tags' do
            let(:response_body) { { pagination: {}, response_body: {} } }

            it 'returns an instantiated tag from the response' do
              subject

              expect(json_response['id']).to eq(repository.id)
              expect(response.body).to include('tags')
              expect(json_response['tags'].count).to eq(0)
              expect(json_response['tags']).to be_empty
            end
          end
        end

        context 'when the GitLab API is not supported' do
          before do
            stub_container_registry_gitlab_api_support(supported: false)
          end

          it_behaves_like 'returning a repository and its tags'
        end

        context 'with a network error' do
          before do
            stub_container_registry_network_error(client_method: :repository_tags)
          end

          it 'returns a connection error message' do
            subject

            expect(response).to have_gitlab_http_status(:service_unavailable)
            expect(json_response['message']).to include('We are having trouble connecting to the Container Registry')
          end
        end
      end

      context 'with tags_count param' do
        let(:url) { "/registry/repositories/#{repository.id}?tags_count=true" }

        before do
          stub_container_registry_tags(repository: repository.path, tags: %w[rootA latest], with_manifest: true)
        end

        it 'returns a repository and its tags_count' do
          subject

          expect(response.body).to include('tags_count')
          expect(json_response['tags_count']).to eq(2)
        end
      end

      context 'with size param' do
        let(:url) { "/registry/repositories/#{repository.id}?size=true" }

        it 'returns a repository and its size' do
          stub_container_registry_gitlab_api_support(supported: true) do |client|
            stub_container_registry_gitlab_api_repository_details(
              client,
              path: repository.path,
              size_bytes: 12345,
              sizing: :self
            )
          end

          subject

          expect(json_response['size']).to eq(12345)
        end

        context 'with a network error' do
          it 'returns an error message' do
            stub_container_registry_gitlab_api_network_error

            subject

            expect(response).to have_gitlab_http_status(:service_unavailable)
            expect(json_response['message']).to include('We are having trouble connecting to the Container Registry')
          end
        end

        context 'with not supporting the gitlab api' do
          it 'returns nil' do
            stub_container_registry_gitlab_api_support(supported: false)

            subject

            expect(json_response['size']).to eq(nil)
          end
        end
      end
    end

    context 'with invalid repository id' do
      let(:url) { "/registry/repositories/#{non_existing_record_id}" }

      it_behaves_like 'returning response status', :not_found
    end
  end
end
