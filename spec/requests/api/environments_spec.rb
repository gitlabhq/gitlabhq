# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Environments, feature_category: :continuous_delivery do
  let_it_be(:user) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, :private, :repository, namespace: user.namespace, maintainers: user, developers: developer, reporters: reporter) }
  let_it_be_with_reload(:environment) { create(:environment, :auto_stop_always, project: project, description: 'description') }

  describe 'GET /projects/:id/environments', :aggregate_failures do
    context 'as member of the project' do
      it 'returns project environments' do
        get api("/projects/#{project.id}/environments", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/environments')
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(1)
        expect(json_response.first['name']).to eq(environment.name)
        expect(json_response.first['tier']).to eq(environment.tier)
        expect(json_response.first['description']).to eq(environment.description)
        expect(json_response.first['external_url']).to eq(environment.external_url)
        expect(json_response.first['project']).to match_schema('public_api/v4/project')
        expect(json_response.first).not_to have_key('last_deployment')
        expect(json_response.first['auto_stop_setting']).to eq('always')
      end

      it 'returns 200 HTTP status when using JOB-TOKEN auth' do
        job = create(:ci_build, :running, project: project, user: user)

        get api("/projects/#{project.id}/environments"), params: { job_token: job.token }

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when filtering' do
        let_it_be(:stopped_environment) { create(:environment, :stopped, project: project) }

        it 'returns environment by name' do
          get api("/projects/#{project.id}/environments?name=#{environment.name}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(1)
          expect(json_response.first['name']).to eq(environment.name)
        end

        it 'returns no environment by non-existent name' do
          get api("/projects/#{project.id}/environments?name=test", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(0)
        end

        it 'returns environments by name_like' do
          get api("/projects/#{project.id}/environments?search=envir", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(2)
        end

        it 'returns no environment by non-existent name_like' do
          get api("/projects/#{project.id}/environments?search=test", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(0)
        end

        context "when params[:search] is less than #{described_class::MIN_SEARCH_LENGTH} characters" do
          it 'returns with status 400' do
            get api("/projects/#{project.id}/environments?search=ab", user)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to include("Search query is less than #{described_class::MIN_SEARCH_LENGTH} characters")
          end
        end

        it 'returns environment by valid state' do
          get api("/projects/#{project.id}/environments?states=available", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(1)
          expect(json_response.first['name']).to eq(environment.name)
        end

        it 'returns all environments when state is not specified' do
          get api("/projects/#{project.id}/environments", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(2)
          expect(json_response.first['name']).to eq(environment.name)
          expect(json_response.last['name']).to eq(stopped_environment.name)
        end

        it 'returns a 400 when filtering by invalid state' do
          get api("/projects/#{project.id}/environments?states=test", user)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('states does not have a valid value')
        end
      end
    end

    context 'as non member' do
      it 'returns a 404 status code' do
        get api("/projects/#{project.id}/environments", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'enforcing job token policies', :read_environments do
      let(:request) do
        get api("/projects/#{source_project.id}/environments"), params: { job_token: target_job.token }
      end
    end
  end

  describe 'POST /projects/:id/environments' do
    it_behaves_like 'enforcing job token policies', :admin_environments do
      let(:request) do
        post api("/projects/#{source_project.id}/environments"),
          params: { name: "mepmep", tier: 'staging', description: 'description', job_token: target_job.token }
      end
    end

    context 'as a member' do
      it 'creates an environment with valid params' do
        post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", tier: 'staging', description: 'description' }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/environment')
        expect(json_response['name']).to eq('mepmep')
        expect(json_response['description']).to eq('description')
        expect(json_response['slug']).to eq('mepmep')
        expect(json_response['tier']).to eq('staging')
        expect(json_response['external']).to be nil
        expect(json_response['auto_stop_setting']).to eq('always')
      end

      context 'when associating a cluster agent' do
        let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }
        let_it_be(:foreign_cluster_agent) { create(:cluster_agent) }

        it 'creates an environment with associated cluster agent' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", cluster_agent_id: cluster_agent.id }

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/environment')
          expect(json_response['cluster_agent']).to be_present
        end

        it 'creates an environment with associated kubernetes namespace' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", cluster_agent_id: cluster_agent.id, kubernetes_namespace: 'flux-system' }

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/environment')
          expect(json_response['cluster_agent']).to be_present
          expect(json_response['kubernetes_namespace']).to eq('flux-system')
        end

        it 'creates an environment with associated flux resource path' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", cluster_agent_id: cluster_agent.id, kubernetes_namespace: 'flux-system', flux_resource_path: 'HelmRelease/flux-system' }

          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/environment')
          expect(json_response['cluster_agent']).to be_present
          expect(json_response['kubernetes_namespace']).to eq('flux-system')
          expect(json_response['flux_resource_path']).to eq('HelmRelease/flux-system')
        end

        it 'fails to create environment with kubernetes namespace but no cluster agent' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", kubernetes_namespace: 'flux-system' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['kubernetes_namespace']).to eq(['cannot be set without a cluster agent'])
        end

        it 'fails to create environment with flux resource path but no cluster agent and kubernetes namespace' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", flux_resource_path: 'HelmRelease/flux-system' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['flux_resource_path']).to eq(['cannot be set without a kubernetes namespace'])
        end

        it 'fails to create environment with flux resource path but no cluster agent' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", kubernetes_namespace: 'flux-system', flux_resource_path: 'HelmRelease/flux-system' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['kubernetes_namespace']).to eq(['cannot be set without a cluster agent'])
        end

        it 'fails to create environment with cluster agent and flux resource path but no kubernetes namespace' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", cluster_agent: cluster_agent.id, flux_resource_path: 'HelmRelease/flux-system' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['flux_resource_path']).to eq(['cannot be set without a kubernetes namespace'])
        end

        it 'fails to create environment with a non existing cluster agent' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", cluster_agent_id: non_existing_record_id }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("400 Bad request - cluster agent doesn't exist or cannot be associated with this environment")
        end

        it 'fails to create environment with a foreign cluster agent' do
          post api("/projects/#{project.id}/environments", user), params: { name: "mepmep", cluster_agent_id: foreign_cluster_agent.id }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq("400 Bad request - cluster agent doesn't exist or cannot be associated with this environment")
        end
      end

      it 'returns 200 HTTP status when using JOB-TOKEN auth' do
        job = create(:ci_build, :running, project: project, user: user)

        post api("/projects/#{project.id}/environments"), params: { name: "mepmep", job_token: job.token }

        expect(response).to have_gitlab_http_status(:created)
      end

      it 'requires name to be passed' do
        post api("/projects/#{project.id}/environments", user), params: { external_url: 'test.gitlab.com' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns a 400 if environment already exists' do
        post api("/projects/#{project.id}/environments", user), params: { name: environment.name }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns a 400 if slug is specified' do
        post api("/projects/#{project.id}/environments", user), params: { name: "foo", slug: "foo" }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response["error"]).to eq("slug is automatically generated and cannot be changed")
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        post api("/projects/#{project.id}/environments", non_member), params: { name: 'gitlab.com' }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns a 400 when the required params are missing' do
        post api("/projects/#{non_existing_record_id}/environments", non_member), params: { external_url: 'http://env.git.com' }
      end
    end
  end

  describe 'POST /projects/:id/environments/stop_stale' do
    it_behaves_like 'enforcing job token policies', :admin_environments do
      let(:request) do
        post api("/projects/#{source_project.id}/environments/stop_stale"),
          params: { before: 1.week.ago.to_date.to_s, job_token: target_job.token }
      end
    end

    context 'as a maintainer' do
      it 'returns a 200' do
        post api("/projects/#{project.id}/environments/stop_stale", user), params: { before: 1.week.ago.to_date.to_s }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns 200 HTTP status when using JOB-TOKEN auth' do
        job = create(:ci_build, :running, project: project, user: user)

        post api("/projects/#{project.id}/environments/stop_stale"),
          params: { before: 1.week.ago.to_date.to_s, job_token: job.token }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns a 400 for bad input date' do
        post api("/projects/#{project.id}/environments/stop_stale", user), params: { before: 1.day.ago.to_date.to_s }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('400 Bad request - Invalid Date')
      end

      it 'returns a 400 for service error' do
        expect_next_instance_of(::Environments::StopStaleService) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Test Error'))
        end

        post api("/projects/#{project.id}/environments/stop_stale", user), params: { before: 1.week.ago.to_date.to_s }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('Test Error')
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        post api("/projects/#{project.id}/environments/stop_stale", non_member), params: { before: 1.week.ago.to_date.to_s }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'a developer' do
      it 'rejects the request' do
        post api("/projects/#{project.id}/environments/stop_stale", developer), params: { before: 1.week.ago.to_date.to_s }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /projects/:id/environments/:environment_id' do
    let_it_be(:url) { 'https://mepmep.whatever.ninja' }

    it_behaves_like 'enforcing job token policies', :admin_environments do
      let(:request) do
        put api("/projects/#{source_project.id}/environments/#{environment.id}"),
          params: { tier: 'production', job_token: target_job.token }
      end
    end

    it 'returns a 200 if external_url is changed' do
      put api("/projects/#{project.id}/environments/#{environment.id}", user),
        params: { external_url: url }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/environment')
      expect(json_response['external_url']).to eq(url)
    end

    it 'returns a 200 if description is changed' do
      put api("/projects/#{project.id}/environments/#{environment.id}", user),
        params: { description: 'new description' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/environment')
      expect(json_response['description']).to eq('new description')
    end

    it 'returns a 200 if tier is changed' do
      put api("/projects/#{project.id}/environments/#{environment.id}", user),
        params: { tier: 'production' }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/environment')
      expect(json_response['tier']).to eq('production')
    end

    it 'returns 200 HTTP status when using JOB-TOKEN auth' do
      job = create(:ci_build, :running, project: project, user: user)

      put api("/projects/#{project.id}/environments/#{environment.id}"),
        params: { tier: 'production', job_token: job.token }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 200 HTTP status when auto_stop_setting is changed' do
      job = create(:ci_build, :running, project: project, user: user)

      put api("/projects/#{project.id}/environments/#{environment.id}"),
        params: { auto_stop_setting: 'with_action', job_token: job.token }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['auto_stop_setting']).to eq('with_action')
    end

    context 'when associating a cluster agent' do
      let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }
      let_it_be(:foreign_cluster_agent) { create(:cluster_agent) }

      it 'updates an environment with associated cluster agent' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { cluster_agent_id: cluster_agent.id }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/environment')
        expect(json_response['cluster_agent']).to be_present
      end

      it 'updates an environment to remove cluster agent' do
        environment.update!(cluster_agent_id: cluster_agent.id)

        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { cluster_agent_id: nil }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/environment')
        expect(json_response['cluster_agent']).not_to be_present
      end

      it 'updates an environment with associated kubernetes namespace' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { cluster_agent_id: cluster_agent.id, kubernetes_namespace: 'flux-system' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/environment')
        expect(json_response['cluster_agent']).to be_present
        expect(json_response['kubernetes_namespace']).to eq('flux-system')
      end

      it 'updates an environment with associated flux resource path' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { cluster_agent_id: cluster_agent.id, kubernetes_namespace: 'flux-system', flux_resource_path: 'HelmRelease/flux-system' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/environment')
        expect(json_response['cluster_agent']).to be_present
        expect(json_response['kubernetes_namespace']).to eq('flux-system')
        expect(json_response['flux_resource_path']).to eq('HelmRelease/flux-system')
      end

      it 'fails to update environment with kubernetes namespace but no cluster agent' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { kubernetes_namespace: 'flux-system' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['kubernetes_namespace']).to eq(['cannot be set without a cluster agent'])
      end

      it 'fails to update environment with flux resource path but no cluster agent and kubernetes namespace' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { flux_resource_path: 'HelmRelease/flux-system' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['flux_resource_path']).to eq(['cannot be set without a kubernetes namespace'])
      end

      it 'fails to update environment with flux resource path but no cluster agent' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { kubernetes_namespace: 'flux-system', flux_resource_path: 'HelmRelease/flux-system' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['kubernetes_namespace']).to eq(['cannot be set without a cluster agent'])
      end

      it 'fails to update environment with cluster agent and flux resource path but no kubernetes namespace' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { cluster_agent_id: cluster_agent.id, flux_resource_path: 'HelmRelease/flux-system' }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['flux_resource_path']).to eq(['cannot be set without a kubernetes namespace'])
      end

      it 'fails to update environment by removing cluster agent when kubernetes namespace is still associated' do
        environment.update!(cluster_agent_id: cluster_agent.id, kubernetes_namespace: 'flux-system')

        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { cluster_agent_id: nil }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['kubernetes_namespace']).to eq(['cannot be set without a cluster agent'])
      end

      it 'fails to update environment by removing kubernetes namespace when flux_resource_path is still associated' do
        environment.update!(cluster_agent_id: cluster_agent.id, kubernetes_namespace: 'flux-system', flux_resource_path: 'HelmRelease/flux-system')

        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { kubernetes_namespace: nil }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['flux_resource_path']).to eq(['cannot be set without a kubernetes namespace'])
      end

      it 'leaves cluster agent unchanged when not specified in update' do
        environment.update!(cluster_agent_id: cluster_agent.id)

        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { external_url: url }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/environment')
        expect(json_response['cluster_agent']).to be_present
      end

      it 'fails to create environment with a non existing cluster agent' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { cluster_agent_id: non_existing_record_id }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq("400 Bad request - cluster agent doesn't exist or cannot be associated with this environment")
      end

      it 'fails to create environment with a foreign cluster agent' do
        put api("/projects/#{project.id}/environments/#{environment.id}", user), params: { cluster_agent_id: foreign_cluster_agent.id }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq("400 Bad request - cluster agent doesn't exist or cannot be associated with this environment")
      end
    end

    it "won't allow slug to be changed" do
      slug = environment.slug
      api_url = api("/projects/#{project.id}/environments/#{environment.id}", user)
      put api_url, params: { slug: slug + "-foo" }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response["error"]).to eq("slug is automatically generated and cannot be changed")
    end

    it 'returns a 404 if the environment does not exist' do
      put api("/projects/#{project.id}/environments/#{non_existing_record_id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'DELETE /projects/:id/environments/:environment_id' do
    it_behaves_like 'enforcing job token policies', :admin_environments do
      before do
        environment.stop
      end

      let(:request) do
        delete api("/projects/#{source_project.id}/environments/#{environment.id}"),
          params: { job_token: target_job.token }
      end
    end

    context 'as a maintainer' do
      it "rejects the requests in environment isn't stopped" do
        delete api("/projects/#{project.id}/environments/#{environment.id}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns a 204 for stopped environment' do
        environment.stop

        delete api("/projects/#{project.id}/environments/#{environment.id}", user)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'returns 204 HTTP status when using JOB-TOKEN auth' do
        environment.stop

        job = create(:ci_build, :running, project: project, user: user)

        delete api("/projects/#{project.id}/environments/#{environment.id}"),
          params: { job_token: job.token }

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'returns a 404 for non existing id' do
        delete api("/projects/#{project.id}/environments/#{non_existing_record_id}", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Not found')
      end

      it_behaves_like '412 response' do
        before do
          environment.stop
        end

        let(:request) { api("/projects/#{project.id}/environments/#{environment.id}", user) }
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        delete api("/projects/#{project.id}/environments/#{environment.id}", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /projects/:id/environments/:environment_id/stop' do
    it_behaves_like 'enforcing job token policies', :admin_environments do
      let(:request) do
        post api("/projects/#{source_project.id}/environments/#{environment.id}/stop"),
          params: { job_token: target_job.token }
      end
    end

    context 'as a maintainer' do
      context 'with a stoppable environment' do
        before do
          environment.update!(state: :available)
        end

        it 'returns a 200' do
          post api("/projects/#{project.id}/environments/#{environment.id}/stop", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/environment')
          expect(environment.reload).to be_stopped
        end

        it 'returns 200 HTTP status when using JOB-TOKEN auth' do
          job = create(:ci_build, :running, project: project, user: user)

          post api("/projects/#{project.id}/environments/#{environment.id}/stop"),
            params: { job_token: job.token }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      it 'returns a 404 for non existing id' do
        post api("/projects/#{project.id}/environments/#{non_existing_record_id}/stop", user)

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 Not found')
      end
    end

    context 'as a reporter' do
      it 'rejects the request' do
        post api("/projects/#{project.id}/environments/#{environment.id}/stop", reporter)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'as a developer' do
      it 'returns a 200' do
        post api("/projects/#{project.id}/environments/#{environment.id}/stop", developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/environment')
        expect(environment.reload).to be_stopped
      end
    end

    context 'a non member' do
      it 'rejects the request' do
        post api("/projects/#{project.id}/environments/#{environment.id}/stop", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/environments/:environment_id' do
    let_it_be(:bridge_job) { create(:ci_bridge, :running, project: project, user: user) }
    let_it_be(:build_job) { create(:ci_build, :running, project: project, user: user) }

    it_behaves_like 'enforcing job token policies', :read_environments do
      let(:request) do
        get api("/projects/#{source_project.id}/environments/#{environment.id}"),
          params: { job_token: target_job.token }
      end
    end

    context 'as member of the project' do
      shared_examples "returns project environments" do
        it 'returns expected response' do
          create(
            :deployment,
            :success,
            project: project,
            environment: environment,
            deployable: job
          )

          environment.update!(
            cluster_agent: create(:cluster_agent, project: project),
            kubernetes_namespace: 'flux-system',
            flux_resource_path: 'HelmRelease/flux-system',
            auto_stop_setting: 'always'
          )

          get api("/projects/#{project.id}/environments/#{environment.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/environment')
          expect(json_response['last_deployment']).to be_present
          expect(json_response['cluster_agent']).to be_present
          expect(json_response['kubernetes_namespace']).to eq('flux-system')
          expect(json_response['flux_resource_path']).to eq('HelmRelease/flux-system')
          expect(json_response['auto_stop_setting']).to eq('always')
        end
      end

      context "when the deployable is a bridge" do
        it_behaves_like "returns project environments" do
          let(:job) { bridge_job }
        end

        # No test for Ci::Bridge JOB-TOKEN auth because it doesn't implement the `.token` method.
      end

      context "when the deployable is a build" do
        it_behaves_like "returns project environments" do
          let(:job) { build_job }
        end

        it 'returns 200 HTTP status when using JOB-TOKEN auth' do
          get(
            api("/projects/#{project.id}/environments/#{environment.id}"),
            params: { job_token: build_job.token }
          )

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context "when auto_stop_at is present" do
        before do
          environment.update!(auto_stop_at: Time.current)
        end

        it "returns the expected response" do
          get api("/projects/#{project.id}/environments/#{environment.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/environment')
          expect(json_response['auto_stop_at']).to be_present
        end
      end

      context "when auto_stop_at is not present" do
        before do
          environment.update!(auto_stop_at: nil)
        end

        it "returns the expected response" do
          get api("/projects/#{project.id}/environments/#{environment.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/environment')
          expect(json_response['auto_stop_at']).to be_nil
        end
      end
    end

    context 'as a reporter' do
      it 'does not expose the cluster agent and related fields' do
        environment.update!(
          cluster_agent: create(:cluster_agent, project: project),
          kubernetes_namespace: 'flux-system',
          flux_resource_path: 'HelmRelease/flux-system'
        )

        get api("/projects/#{project.id}/environments/#{environment.id}", reporter)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/environment')
        expect(json_response['cluster_agent']).not_to be_present
        expect(json_response['kubernetes_namespace']).not_to be_present
        expect(json_response['flux_resource_path']).not_to be_present
      end
    end

    context 'as non member' do
      shared_examples 'environment will not be found' do
        it 'returns a 404 status code' do
          get api("/projects/#{project.id}/environments/#{environment.id}", non_member)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when the deployable is a bridge" do
        it_behaves_like "environment will not be found" do
          let(:job) { bridge_job }
        end
      end

      context "when the deployable is a build" do
        it_behaves_like "environment will not be found" do
          let(:job) { build_job }
        end
      end
    end
  end

  describe "DELETE /projects/:id/environments/review_apps" do
    shared_examples "delete stopped review environments" do
      around do |example|
        freeze_time { example.run }
      end

      it "deletes the old stopped review apps" do
        old_stopped_review_env = create(:environment, :with_review_app, :stopped, created_at: 31.days.ago, project: project)
        new_stopped_review_env = create(:environment, :with_review_app, :stopped, project: project)
        old_active_review_env  = create(:environment, :with_review_app, :available, created_at: 31.days.ago, project: project)
        old_stopped_other_env  = create(:environment, :stopped, created_at: 31.days.ago, project: project)
        new_stopped_other_env  = create(:environment, :stopped, project: project)
        old_active_other_env   = create(:environment, :available, created_at: 31.days.ago, project: project)

        delete api("/projects/#{project.id}/environments/review_apps", current_user), params: { dry_run: false }
        project.environments.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response["scheduled_entries"].size).to eq(1)
        expect(json_response["scheduled_entries"].first["id"]).to eq(old_stopped_review_env.id)
        expect(json_response["unprocessable_entries"].size).to eq(0)
        expect(json_response["scheduled_entries"]).to match_schema('public_api/v4/basic_environments')
        expect(json_response["unprocessable_entries"]).to match_schema('public_api/v4/basic_environments')

        expect(old_stopped_review_env.reload.auto_delete_at).to eq(1.week.from_now)
        expect(new_stopped_review_env.reload.auto_delete_at).to be_nil
        expect(old_active_review_env.reload.auto_delete_at).to be_nil
        expect(old_stopped_other_env.reload.auto_delete_at).to be_nil
        expect(new_stopped_other_env.reload.auto_delete_at).to be_nil
        expect(old_active_other_env.reload.auto_delete_at).to be_nil
      end
    end

    it_behaves_like 'enforcing job token policies', :admin_environments do
      before_all do
        create(:environment, :with_review_app, :stopped, created_at: 31.days.ago, project: project)
      end

      let(:request) do
        delete api("/projects/#{source_project.id}/environments/review_apps"), params: { job_token: target_job.token }
      end
    end

    context "as a maintainer" do
      it_behaves_like "delete stopped review environments" do
        let(:current_user) { user }
      end
    end

    context "as a developer" do
      let(:developer) { create(:user) }

      before do
        project.add_developer(developer)
      end

      it_behaves_like "delete stopped review environments" do
        let(:current_user) { developer }
      end
    end

    context "as a reporter" do
      it "rejects the request" do
        delete api("/projects/#{project.id}/environments/review_apps", reporter)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "as a non member" do
      it "rejects the request" do
        delete api("/projects/#{project.id}/environments/review_apps", non_member)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
