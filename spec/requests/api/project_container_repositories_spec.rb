# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectContainerRepositories do
  include ExclusiveLeaseHelpers

  set(:project) { create(:project, :private) }
  set(:maintainer) { create(:user) }
  set(:developer) { create(:user) }
  set(:reporter) { create(:user) }
  set(:guest) { create(:user) }

  let(:root_repository) { create(:container_repository, :root, project: project) }
  let(:test_repository) { create(:container_repository, project: project) }

  let(:users) do
    {
      anonymous: nil,
      developer: developer,
      guest: guest,
      maintainer: maintainer,
      reporter: reporter
    }
  end

  let(:api_user) { maintainer }

  before do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)

    stub_feature_flags(container_registry_api: true)
    stub_container_registry_config(enabled: true)

    root_repository
    test_repository
  end

  describe 'GET /projects/:id/registry/repositories' do
    let(:url) { "/projects/#{project.id}/registry/repositories" }

    subject { get api(url, api_user) }

    it_behaves_like 'rejected container repository access', :guest, :forbidden
    it_behaves_like 'rejected container repository access', :anonymous, :not_found
    it_behaves_like 'a gitlab tracking event', described_class.name, 'list_repositories'

    it_behaves_like 'returns repositories for allowed users', :reporter, 'project' do
      let(:object) { project }
    end
  end

  describe 'DELETE /projects/:id/registry/repositories/:repository_id' do
    subject { delete api("/projects/#{project.id}/registry/repositories/#{root_repository.id}", api_user) }

    it_behaves_like 'rejected container repository access', :developer, :forbidden
    it_behaves_like 'rejected container repository access', :anonymous, :not_found
    it_behaves_like 'a gitlab tracking event', described_class.name, 'delete_repository'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'schedules removal of repository' do
        expect(DeleteContainerRepositoryWorker).to receive(:perform_async)
          .with(maintainer.id, root_repository.id)

        subject

        expect(response).to have_gitlab_http_status(:accepted)
      end
    end
  end

  describe 'GET /projects/:id/registry/repositories/:repository_id/tags' do
    subject { get api("/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags", api_user) }

    it_behaves_like 'rejected container repository access', :guest, :forbidden
    it_behaves_like 'rejected container repository access', :anonymous, :not_found

    context 'for reporter' do
      let(:api_user) { reporter }

      before do
        stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA latest))
      end

      it_behaves_like 'a gitlab tracking event', described_class.name, 'list_tags'

      it 'returns a list of tags' do
        subject

        expect(json_response.length).to eq(2)
        expect(json_response.map { |repository| repository['name'] }).to eq %w(latest rootA)
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/tags')
      end
    end
  end

  describe 'DELETE /projects/:id/registry/repositories/:repository_id/tags' do
    subject { delete api("/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags", api_user), params: params }

    context 'disallowed' do
      let(:params) do
        { name_regex: 'v10.*' }
      end

      it_behaves_like 'rejected container repository access', :developer, :forbidden
      it_behaves_like 'rejected container repository access', :anonymous, :not_found
      it_behaves_like 'a gitlab tracking event', described_class.name, 'delete_tag_bulk'
    end

    context 'for maintainer' do
      let(:api_user) { maintainer }

      context 'without required parameters' do
        let(:params) { }

        it 'returns bad request' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'passes all declared parameters' do
        let(:params) do
          { name_regex: 'v10.*',
            keep_n: 100,
            older_than: '1 day',
            other: 'some value' }
        end

        let(:worker_params) do
          { name_regex: 'v10.*',
            keep_n: 100,
            older_than: '1 day' }
        end

        let(:lease_key) { "container_repository:cleanup_tags:#{root_repository.id}" }

        it 'schedules cleanup of tags repository' do
          stub_exclusive_lease(lease_key, timeout: 1.hour)
          expect(CleanupContainerRepositoryWorker).to receive(:perform_async)
            .with(maintainer.id, root_repository.id, worker_params)

          subject

          expect(response).to have_gitlab_http_status(:accepted)
        end

        context 'called multiple times in one hour', :clean_gitlab_redis_shared_state do
          it 'returns 400 with an error message' do
            stub_exclusive_lease_taken(lease_key, timeout: 1.hour)
            subject

            expect(response).to have_gitlab_http_status(400)
            expect(response.body).to include('This request has already been made.')
          end

          it 'executes service only for the first time' do
            expect(CleanupContainerRepositoryWorker).to receive(:perform_async).once

            2.times { subject }
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name' do
    subject { get api("/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags/rootA", api_user) }

    it_behaves_like 'rejected container repository access', :guest, :forbidden
    it_behaves_like 'rejected container repository access', :anonymous, :not_found

    context 'for reporter' do
      let(:api_user) { reporter }

      before do
        stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA), with_manifest: true)
      end

      it 'returns a details of tag' do
        subject

        expect(json_response).to include(
          'name' => 'rootA',
          'digest' => 'sha256:4c8e63ca4cb663ce6c688cb06f1c372b088dac5b6d7ad7d49cd620d85cf72a15',
          'revision' => 'd7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac',
          'total_size' => 2319870)
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/tag')
      end
    end
  end

  describe 'DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name' do
    let(:service) { double('service') }

    subject { delete api("/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags/rootA", api_user) }

    it_behaves_like 'rejected container repository access', :reporter, :forbidden
    it_behaves_like 'rejected container repository access', :anonymous, :not_found

    context 'for developer' do
      let(:api_user) { developer }

      context 'when there are multiple tags' do
        before do
          stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA rootB), with_manifest: true)
        end

        it 'properly removes tag' do
          expect(service).to receive(:execute).with(root_repository) { { status: :success } }
          expect(Projects::ContainerRepository::DeleteTagsService).to receive(:new).with(root_repository.project, api_user, tags: %w[rootA]) { service }
          expect(Gitlab::Tracking).to receive(:event).with(described_class.name, 'delete_tag', {})

          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when there\'s only one tag' do
        before do
          stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA), with_manifest: true)
        end

        it 'properly removes tag' do
          expect(service).to receive(:execute).with(root_repository) { { status: :success } }
          expect(Projects::ContainerRepository::DeleteTagsService).to receive(:new).with(root_repository.project, api_user, tags: %w[rootA]) { service }
          expect(Gitlab::Tracking).to receive(:event).with(described_class.name, 'delete_tag', {})

          subject

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
