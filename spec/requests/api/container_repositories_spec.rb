# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ContainerRepositories do
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

      context 'with tags param' do
        let(:url) { "/registry/repositories/#{repository.id}?tags=true" }

        before do
          stub_container_registry_tags(repository: repository.path, tags: %w(rootA latest), with_manifest: true)
        end

        it 'returns a repository and its tags' do
          subject

          expect(json_response['id']).to eq(repository.id)
          expect(response.body).to include('tags')
        end
      end

      context 'with tags_count param' do
        let(:url) { "/registry/repositories/#{repository.id}?tags_count=true" }

        before do
          stub_container_registry_tags(repository: repository.path, tags: %w(rootA latest), with_manifest: true)
        end

        it 'returns a repository and its tags_count' do
          subject

          expect(response.body).to include('tags_count')
          expect(json_response['tags_count']).to eq(2)
        end
      end
    end

    context 'with invalid repository id' do
      let(:url) { "/registry/repositories/#{non_existing_record_id}" }

      it_behaves_like 'returning response status', :not_found
    end
  end
end
