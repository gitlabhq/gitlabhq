require 'spec_helper'

describe API::ContainerRegistry do
  include ExclusiveLeaseHelpers

  set(:project) { create(:project, :private) }
  set(:maintainer) { create(:user) }
  set(:developer) { create(:user) }
  set(:reporter) { create(:user) }
  set(:guest) { create(:user) }

  let(:root_repository) { create(:container_repository, :root, project: project) }
  let(:test_repository) { create(:container_repository, project: project) }

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

  shared_examples 'being disallowed' do |param|
    context "for #{param}" do
      let(:api_user) { public_send(param) }

      it 'returns access denied' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "for anonymous" do
      let(:api_user) { nil }

      it 'returns not found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/registry/repositories' do
    subject { get api("/projects/#{project.id}/registry/repositories", api_user) }

    it_behaves_like 'being disallowed', :guest

    context 'for reporter' do
      let(:api_user) { reporter }

      it 'returns a list of repositories' do
        subject

        expect(json_response.length).to eq(2)
        expect(json_response.map { |repository| repository['id'] }).to contain_exactly(
          root_repository.id, test_repository.id)
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/repositories')
      end
    end
  end

  describe 'DELETE /projects/:id/registry/repositories/:repository_id' do
    subject { delete api("/projects/#{project.id}/registry/repositories/#{root_repository.id}", api_user) }

    it_behaves_like 'being disallowed', :developer

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

    it_behaves_like 'being disallowed', :guest

    context 'for reporter' do
      let(:api_user) { reporter }

      before do
        stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA latest))
      end

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

    it_behaves_like 'being disallowed', :developer do
      let(:params) do
        { name_regex: 'v10.*' }
      end
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

        context 'called multiple times in one hour' do
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

    it_behaves_like 'being disallowed', :guest

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
    subject { delete api("/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags/rootA", api_user) }

    it_behaves_like 'being disallowed', :reporter

    context 'for developer' do
      let(:api_user) { developer }

      before do
        stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA), with_manifest: true)
      end

      it 'properly removes tag' do
        expect_any_instance_of(ContainerRegistry::Client)
          .to receive(:delete_repository_tag).with(root_repository.path,
            'sha256:4c8e63ca4cb663ce6c688cb06f1c372b088dac5b6d7ad7d49cd620d85cf72a15')

        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
