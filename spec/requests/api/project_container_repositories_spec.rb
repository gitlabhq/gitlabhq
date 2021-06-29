# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectContainerRepositories do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:project2) { create(:project, :public) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:root_repository) { create(:container_repository, :root, project: project) }
  let(:test_repository) { create(:container_repository, project: project) }
  let(:root_repository2) { create(:container_repository, :root, project: project2) }

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
  let(:job) { create(:ci_build, :running, user: api_user, project: project) }
  let(:job2) { create(:ci_build, :running, user: api_user, project: project2) }

  let(:method) { :get }
  let(:params) { {} }

  let(:snowplow_gitlab_standard_context) { { user: api_user, project: project, namespace: project.namespace } }

  before_all do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)

    project2.add_maintainer(maintainer)
    project2.add_developer(developer)
    project2.add_reporter(reporter)
    project2.add_guest(guest)
  end

  before do
    root_repository
    test_repository

    stub_container_registry_config(enabled: true)
  end

  shared_context 'using API user' do
    subject { public_send(method, api(url, api_user), params: params) }
  end

  shared_context 'using job token' do
    before do
      stub_exclusive_lease
      stub_feature_flags(ci_job_token_scope: true)
    end

    subject { public_send(method, api(url), params: params.merge({ job_token: job.token })) }
  end

  shared_context 'using job token from another project' do
    before do
      stub_exclusive_lease
      stub_feature_flags(ci_job_token_scope: true)
    end

    subject { public_send(method, api(url), params: { job_token: job2.token }) }
  end

  shared_context 'using job token while ci_job_token_scope feature flag is disabled' do
    before do
      stub_exclusive_lease
      stub_feature_flags(ci_job_token_scope: false)
    end

    subject { public_send(method, api(url), params: params.merge({ job_token: job.token })) }
  end

  shared_examples 'rejected job token scopes' do
    include_context 'using job token from another project' do
      it_behaves_like 'rejected container repository access', :maintainer, :forbidden
    end

    include_context 'using job token while ci_job_token_scope feature flag is disabled' do
      it_behaves_like 'rejected container repository access', :maintainer, :forbidden
    end
  end

  describe 'GET /projects/:id/registry/repositories' do
    let(:url) { "/projects/#{project.id}/registry/repositories" }

    ['using API user', 'using job token'].each do |context|
      context context do
        include_context context

        it_behaves_like 'rejected container repository access', :guest, :forbidden unless context == 'using job token'
        it_behaves_like 'rejected container repository access', :anonymous, :not_found
        it_behaves_like 'a package tracking event', described_class.name, 'list_repositories'

        it_behaves_like 'returns repositories for allowed users', :reporter, 'project' do
          let(:object) { project }
        end
      end
    end

    include_examples 'rejected job token scopes'
  end

  describe 'DELETE /projects/:id/registry/repositories/:repository_id' do
    let(:method) { :delete }
    let(:url) { "/projects/#{project.id}/registry/repositories/#{root_repository.id}" }

    ['using API user', 'using job token'].each do |context|
      context context do
        include_context context

        it_behaves_like 'rejected container repository access', :developer, :forbidden
        it_behaves_like 'rejected container repository access', :anonymous, :not_found
        it_behaves_like 'a package tracking event', described_class.name, 'delete_repository'

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
    end

    include_examples 'rejected job token scopes'
  end

  describe 'GET /projects/:id/registry/repositories/:repository_id/tags' do
    let(:url) { "/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags" }

    ['using API user', 'using job token'].each do |context|
      context context do
        include_context context

        it_behaves_like 'rejected container repository access', :guest, :forbidden unless context == 'using job token'
        it_behaves_like 'rejected container repository access', :anonymous, :not_found

        context 'for reporter' do
          let(:api_user) { reporter }

          before do
            stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA latest))
          end

          it_behaves_like 'a package tracking event', described_class.name, 'list_tags'

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
    end

    include_examples 'rejected job token scopes'
  end

  describe 'DELETE /projects/:id/registry/repositories/:repository_id/tags' do
    let(:method) { :delete }
    let(:url) { "/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags" }

    ['using API user', 'using job token'].each do |context|
      context context do
        include_context context

        context 'disallowed' do
          let(:params) do
            { name_regex_delete: 'v10.*' }
          end

          it_behaves_like 'rejected container repository access', :developer, :forbidden
          it_behaves_like 'rejected container repository access', :anonymous, :not_found
          it_behaves_like 'a package tracking event', described_class.name, 'delete_tag_bulk'
        end

        context 'for maintainer' do
          let(:api_user) { maintainer }

          context 'without required parameters' do
            it 'returns bad request' do
              subject

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'without name_regex' do
            let(:params) do
              { keep_n: 100,
                older_than: '1 day',
                other: 'some value' }
            end

            it 'returns bad request' do
              subject

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'passes all declared parameters' do
            let(:params) do
              { name_regex_delete: 'v10.*',
                name_regex_keep: 'v10.1.*',
                keep_n: 100,
                older_than: '1 day',
                other: 'some value' }
            end

            let(:worker_params) do
              { name_regex: nil,
                name_regex_delete: 'v10.*',
                name_regex_keep: 'v10.1.*',
                keep_n: 100,
                older_than: '1 day',
                container_expiration_policy: false }
            end

            let(:lease_key) { "container_repository:cleanup_tags:#{root_repository.id}" }

            it 'schedules cleanup of tags repository' do
              stub_last_activity_update
              expect(CleanupContainerRepositoryWorker).to receive(:perform_async)
                .with(maintainer.id, root_repository.id, worker_params)

              subject

              expect(response).to have_gitlab_http_status(:accepted)
            end

            context 'called multiple times in one hour', :clean_gitlab_redis_shared_state do
              it 'returns 400 with an error message' do
                stub_exclusive_lease_taken(lease_key, timeout: 1.hour)
                subject

                expect(response).to have_gitlab_http_status(:bad_request)
                expect(response.body).to include('This request has already been made.')
              end

              it 'executes service only for the first time' do
                expect(CleanupContainerRepositoryWorker).to receive(:perform_async).once

                2.times { subject }
              end
            end
          end

          context 'with deprecated name_regex param' do
            let(:params) do
              { name_regex: 'v10.*',
                name_regex_keep: 'v10.1.*',
                keep_n: 100,
                older_than: '1 day',
                other: 'some value' }
            end

            let(:worker_params) do
              { name_regex: 'v10.*',
                name_regex_delete: nil,
                name_regex_keep: 'v10.1.*',
                keep_n: 100,
                older_than: '1 day',
                container_expiration_policy: false }
            end

            it 'schedules cleanup of tags repository' do
              stub_last_activity_update
              expect(CleanupContainerRepositoryWorker).to receive(:perform_async)
                .with(maintainer.id, root_repository.id, worker_params)

              subject

              expect(response).to have_gitlab_http_status(:accepted)
            end
          end

          context 'with invalid regex' do
            let(:invalid_regex) { '*v10.' }

            RSpec.shared_examples 'rejecting the invalid regex' do |param_name|
              it 'does not enqueue a job' do
                expect(CleanupContainerRepositoryWorker).not_to receive(:perform_async)

                subject
              end

              it_behaves_like 'returning response status', :bad_request

              it 'returns an error message' do
                subject

                expect(json_response['error']).to include("#{param_name} is an invalid regexp")
              end
            end

            before do
              stub_last_activity_update
            end

            %i[name_regex_delete name_regex name_regex_keep].each do |param_name|
              context "for #{param_name}" do
                let(:params) { { param_name => invalid_regex } }

                it_behaves_like 'rejecting the invalid regex', param_name
              end
            end
          end
        end
      end
    end

    include_examples 'rejected job token scopes'
  end

  describe 'GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name' do
    let(:url) { "/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags/rootA" }

    ['using API user', 'using job token'].each do |context|
      context context do
        include_context context

        it_behaves_like 'rejected container repository access', :guest, :forbidden unless context == 'using job token'
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
    end

    include_examples 'rejected job token scopes'
  end

  describe 'DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name' do
    let(:method) { :delete }
    let(:url) { "/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags/rootA" }
    let(:service) { double('service') }

    ['using API user', 'using job token'].each do |context|
      context context do
        include_context context

        it_behaves_like 'rejected container repository access', :reporter, :forbidden
        it_behaves_like 'rejected container repository access', :anonymous, :not_found

        context 'for developer', :snowplow do
          let(:api_user) { developer }

          context 'when there are multiple tags' do
            before do
              stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA rootB), with_manifest: true)
            end

            it 'properly removes tag' do
              expect(service).to receive(:execute).with(root_repository) { { status: :success } }
              expect(Projects::ContainerRepository::DeleteTagsService).to receive(:new).with(root_repository.project, api_user, tags: %w[rootA]) { service }

              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect_snowplow_event(category: described_class.name, action: 'delete_tag', project: project, user: api_user, namespace: project.namespace)
            end
          end

          context 'when there\'s only one tag' do
            before do
              stub_container_registry_tags(repository: root_repository.path, tags: %w(rootA), with_manifest: true)
            end

            it 'properly removes tag' do
              expect(service).to receive(:execute).with(root_repository) { { status: :success } }
              expect(Projects::ContainerRepository::DeleteTagsService).to receive(:new).with(root_repository.project, api_user, tags: %w[rootA]) { service }

              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect_snowplow_event(category: described_class.name, action: 'delete_tag', project: project, user: api_user, namespace: project.namespace)
            end
          end
        end
      end
    end

    include_examples 'rejected job token scopes'
  end
end
