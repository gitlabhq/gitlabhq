# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectContainerRepositories, feature_category: :container_registry do
  include ExclusiveLeaseHelpers

  include_context 'container registry client stubs'

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:project2) { create(:project, :public) }
  let_it_be(:maintainer) { create(:user, maintainer_of: [project, project2]) }
  let_it_be(:developer) { create(:user, developer_of: [project, project2]) }
  let_it_be(:reporter) { create(:user, reporter_of: [project, project2]) }
  let_it_be(:guest) { create(:user, guest_of: [project, project2]) }

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

  let(:snowplow_gitlab_standard_context) do
    { user: api_user, project: project, namespace: project.namespace,
      property: 'i_package_container_user' }
  end

  before do
    root_repository
    test_repository

    stub_container_registry_config(enabled: true)
    stub_container_registry_info
  end

  shared_context 'using API user' do
    subject { public_send(method, api(url, api_user), params: params) }
  end

  shared_context 'using job token' do
    before do
      stub_exclusive_lease
    end

    subject { public_send(method, api(url), params: params.merge({ job_token: job.token })) }
  end

  shared_context 'using job token from another project' do
    before do
      stub_exclusive_lease
    end

    subject { public_send(method, api(url), params: { job_token: job2.token }) }
  end

  shared_examples 'rejected job token scopes' do
    include_context 'using job token from another project' do
      it_behaves_like 'rejected container repository access', :maintainer, :forbidden
    end
  end

  describe 'GET /projects/:id/registry/repositories' do
    let(:url) { "/projects/#{project.id}/registry/repositories" }

    context 'using job token' do
      include_context 'using job token' do
        context "when requested project is not equal job's project" do
          let(:url) { "/projects/#{project2.id}/registry/repositories" }

          it_behaves_like 'rejected container repository access',
            :maintainer, :forbidden, "403 Forbidden - This project's CI/CD job token cannot be used to authenticate with the container registry of a different project."
        end
      end
    end

    ['using API user', 'using job token'].each do |context|
      context context do
        include_context context

        it_behaves_like 'rejected container repository access', :guest, :forbidden unless context == 'using job token'
        it_behaves_like 'rejected container repository access', :anonymous, :not_found
        it_behaves_like 'a package tracking event', described_class.name, 'list_repositories'
        it_behaves_like 'handling network errors with the container registry' do
          let(:params) { { tags: true } }
        end

        it_behaves_like 'returns repositories for allowed users', :reporter, 'project' do
          let(:object) { project }
        end

        it_behaves_like 'returns tags for allowed users', :reporter, 'project' do
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

          it 'marks the repository as delete_scheduled' do
            expect { subject }.to change { root_repository.reload.status }.from(nil).to('delete_scheduled')

            expect(response).to have_gitlab_http_status(:accepted)
          end
        end
      end
    end

    include_examples 'rejected job token scopes'
  end

  describe 'GET /projects/:id/registry/repositories/:repository_id/tags' do
    let(:url) { "/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags" }

    shared_examples 'returning values correctly' do
      it 'returns a list of tags' do
        subject

        expect(json_response.length).to eq(2)
        expect(json_response.map { |repository| repository['name'] }).to eq %w[latest rootA]
      end

      it 'returns a matching schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('registry/tags')
      end
    end

    ['using API user', 'using job token'].each do |context|
      context context do
        include_context context

        it_behaves_like 'rejected container repository access', :guest, :forbidden unless context == 'using job token'
        it_behaves_like 'rejected container repository access', :anonymous, :not_found
        it_behaves_like 'handling network errors with the container registry'

        context 'for reporter' do
          let(:api_user) { reporter }

          before do
            stub_container_registry_tags(repository: root_repository.path, tags: %w[rootA latest])
          end

          it_behaves_like 'a package tracking event', described_class.name, 'list_tags'
          it_behaves_like 'returning values correctly'

          context 'when pagination is set to keyset' do
            let(:url) { "/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags?pagination=keyset" }

            context 'when the GitLab API is supported' do
              let_it_be(:tags_response) do
                [
                  {
                    name: 'latest',
                    digest: 'sha256:4c8e63ca4cb663ce6c688cb06f1',
                    config_digest: 'sha256:d7a513a663c1a6dcdba9',
                    size_bytes: 2319870,
                    created_at: 1.minute.ago
                  },
                  {
                    name: 'rootA',
                    digest: 'sha256:4c8e63ca4cb663ce6c688cb06f1',
                    config_digest: 'sha256:d7a513a663c1a6dcdba9',
                    size_bytes: 2319871,
                    created_at: 2.minutes.ago
                  }
                ]
              end

              let(:pagination) do
                {
                  previous: { uri: URI('/test?before=prev-cursor') },
                  next: { uri: URI('/test?n=10&sort=-name&last=last-item') }
                }
              end

              let(:response_body) do
                {
                  pagination: pagination,
                  response_body: ::Gitlab::Json.parse(tags_response.to_json)
                }
              end

              before do
                stub_container_registry_gitlab_api_support(supported: true) do |client|
                  allow(client).to receive(:tags).and_return(response_body)
                end
              end

              using RSpec::Parameterized::TableSyntax
              where(:parameter, :per_page, :sort, :last_param) do
                "per_page=5" | 5  | 'name' | nil
                "last=abc"   | 20 | 'name' | 'abc'
                "sort=asc"   | 20 | 'name' | nil
                "sort=desc"  | 20 | '-name' | nil
                "sort=desc&last=a&per_page=10" | 10 | '-name' | 'a'
              end

              with_them do
                let(:url) { "/projects/#{project.id}/registry/repositories/#{root_repository.id}/tags?pagination=keyset&#{parameter}" }

                it "passes the parameters correctly to the Container Registry API" do
                  expect_next_instances_of(ContainerRegistry::GitlabApiClient, 1) do |client|
                    allow(client).to receive(:supports_gitlab_api?).and_return(true)

                    expect(client).to receive(:tags).with(
                      root_repository.path,
                      page_size: per_page,
                      sort: sort,
                      last: last_param,
                      name: nil,
                      before: nil,
                      referrers: nil,
                      referrer_type: nil
                    )
                  end

                  subject
                end
              end

              context 'when the Gitlab API returns a tag' do
                it_behaves_like 'returning values correctly'
                it_behaves_like 'a package tracking event', described_class.name, 'list_tags'

                it 'returns the correct link to the next page' do
                  subject

                  expect(response.header['Link']).to include('pagination=keyset')
                  expect(response.header['Link']).to include('per_page=10')
                  expect(response.header['Link']).to include('sort=desc')
                  expect(response.header['Link']).to include('last=last-item')
                end

                context 'when there is no pagination link returned' do
                  let(:pagination) { {} }

                  it 'does not return a Link to the next page' do
                    subject

                    expect(response.header).not_to include('Link')
                  end
                end
              end

              context 'when the Gitlab API does not return a tag' do
                let(:tags_response) { [] }

                it 'returns an empty array' do
                  subject
                  expect(json_response).to be_empty
                end
              end
            end

            context 'when the GitLab API is not supported' do
              before do
                stub_container_registry_gitlab_api_support(supported: false)
              end

              it 'returns method not allowed' do
                subject
                expect(response).to have_gitlab_http_status(:method_not_allowed)
              end
            end
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
                older_than: '1 day' }
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
                older_than: '1 day' }
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
          shared_examples 'returning the tag' do
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

          let(:api_user) { reporter }

          context 'when the Gitlab API is supported' do
            before do
              stub_container_registry_gitlab_api_support(supported: true) do |client|
                allow(client).to receive(:tags).and_return(response_body)
              end
            end

            let(:response_body) do
              {
                pagination: {},
                response_body: ::Gitlab::Json.parse(tags_response.to_json)
              }
            end

            context 'when the Gitlab API returns a tag' do
              let_it_be(:tags_response) do
                [
                  {
                    name: 'rootA',
                    digest: 'sha256:4c8e63ca4cb663ce6c688cb06f1c372b088dac5b6d7ad7d49cd620d85cf72a15',
                    config_digest: 'sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac',
                    size_bytes: 2319870,
                    created_at: 1.minute.ago
                  }
                ]
              end

              it_behaves_like 'returning the tag'
            end

            context 'when the Gitlab API returns multiple tags matching the name' do
              let_it_be(:tags_response) do
                [
                  {
                    name: 'rootA',
                    digest: 'sha256:4c8e63ca4cb663ce6c688cb06f1c372b088dac5b6d7ad7d49cd620d85cf72a15',
                    config_digest: 'sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac',
                    size_bytes: 2319870,
                    created_at: 1.minute.ago
                  },
                  {
                    name: 'rootA-1',
                    digest: 'sha256:4c8e63ca4cb663ce6c688cb06f1c372b088dac5b6d7ad7d49cd620d85cf72a15',
                    config_digest: 'sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac',
                    size_bytes: 2319870,
                    created_at: 1.minute.ago
                  },
                  {
                    name: '1-rootA',
                    digest: 'sha256:4c8e63ca4cb663ce6c688cb06f1c372b088dac5b6d7ad7d49cd620d85cf72a15',
                    config_digest: 'sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac',
                    size_bytes: 2319870,
                    created_at: 1.minute.ago
                  }
                ]
              end

              it_behaves_like 'returning the tag'
            end

            context 'when the Gitlab API does not return a tag' do
              let_it_be(:tags_response) { {} }

              it 'returns not found' do
                subject

                expect(response).to have_gitlab_http_status(:not_found)
                expect(json_response['message']).to include('Tag Not Found')
              end
            end
          end

          context 'when the Gitlab API is not supported' do
            before do
              stub_container_registry_gitlab_api_support(supported: false)
              stub_container_registry_tags(repository: root_repository.path, tags: %w[rootA], with_manifest: true)
            end

            it_behaves_like 'returning the tag'
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
          let(:service_ping_context) do
            [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: 'i_package_container_user').to_h]
          end

          context 'when there are multiple tags' do
            before do
              stub_container_registry_tags(repository: root_repository.path, tags: %w[rootA rootB], with_manifest: true)
            end

            it 'properly removes tag' do
              expect(service).to receive(:execute).with(root_repository) { { status: :success } }
              expect(Projects::ContainerRepository::DeleteTagsService)
                .to receive(:new).with(root_repository.project, api_user, tags: %w[rootA]) { service }

              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect_snowplow_event(
                category: described_class.name,
                action: 'delete_tag',
                project: project,
                user: api_user,
                namespace: project.namespace.reload,
                label: 'redis_hll_counters.user_packages.user_packages_total_unique_counts_monthly',
                property: 'i_package_container_user',
                context: service_ping_context
              )
            end
          end

          context 'when there\'s only one tag' do
            before do
              stub_container_registry_tags(repository: root_repository.path, tags: %w[rootA], with_manifest: true)
            end

            it 'properly removes tag' do
              expect(service).to receive(:execute).with(root_repository) { { status: :success } }
              expect(Projects::ContainerRepository::DeleteTagsService)
                .to receive(:new).with(root_repository.project, api_user, tags: %w[rootA]) { service }

              subject

              expect(response).to have_gitlab_http_status(:ok)
              expect_snowplow_event(
                category: described_class.name,
                action: 'delete_tag',
                project: project,
                user: api_user,
                namespace: project.namespace.reload,
                label: 'redis_hll_counters.user_packages.user_packages_total_unique_counts_monthly',
                property: 'i_package_container_user',
                context: service_ping_context
              )
            end
          end
        end
      end
    end

    include_examples 'rejected job token scopes'
  end
end
