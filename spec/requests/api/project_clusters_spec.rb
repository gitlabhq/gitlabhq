# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectClusters do
  include KubernetesHelpers

  let(:current_user) { create(:user) }
  let(:developer_user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(current_user)
    project.add_developer(developer_user)
  end

  describe 'GET /projects/:id/clusters' do
    let!(:extra_cluster) { create(:cluster, :provided_by_gcp, :project) }

    let!(:clusters) do
      create_list(:cluster, 5, :provided_by_gcp, :project, :production_environment,
                  projects: [project])
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        get api("/projects/#{project.id}/clusters", developer_user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        get api("/projects/#{project.id}/clusters", current_user)
      end

      it 'responds with 200' do
        expect(response).to have_gitlab_http_status(200)
      end

      it 'includes pagination headers' do
        expect(response).to include_pagination_headers
      end

      it 'onlies include authorized clusters' do
        cluster_ids = json_response.map { |cluster| cluster['id'] }

        expect(cluster_ids).to match_array(clusters.pluck(:id))
        expect(cluster_ids).not_to include(extra_cluster.id)
      end
    end
  end

  describe 'GET /projects/:id/clusters/:cluster_id' do
    let(:cluster_id) { cluster.id }

    let(:platform_kubernetes) do
      create(:cluster_platform_kubernetes, :configured,
             namespace: 'project-namespace')
    end

    let(:cluster) do
      create(:cluster, :project, :provided_by_gcp, :with_domain,
             platform_kubernetes: platform_kubernetes,
             user: current_user,
             projects: [project])
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        get api("/projects/#{project.id}/clusters/#{cluster_id}", developer_user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        get api("/projects/#{project.id}/clusters/#{cluster_id}", current_user)
      end

      it 'returns specific cluster' do
        expect(json_response['id']).to eq(cluster.id)
      end

      it 'returns cluster information' do
        expect(json_response['provider_type']).to eq('gcp')
        expect(json_response['platform_type']).to eq('kubernetes')
        expect(json_response['environment_scope']).to eq('*')
        expect(json_response['cluster_type']).to eq('project_type')
        expect(json_response['domain']).to eq('example.com')
      end

      it 'returns project information' do
        cluster_project = json_response['project']

        expect(cluster_project['id']).to eq(project.id)
        expect(cluster_project['name']).to eq(project.name)
        expect(cluster_project['path']).to eq(project.path)
      end

      it 'returns kubernetes platform information' do
        platform = json_response['platform_kubernetes']

        expect(platform['api_url']).to eq('https://kubernetes.example.com')
        expect(platform['namespace']).to eq('project-namespace')
        expect(platform['ca_cert']).to be_present
      end

      it 'returns user information' do
        user = json_response['user']

        expect(user['id']).to eq(current_user.id)
        expect(user['username']).to eq(current_user.username)
      end

      it 'returns GCP provider information' do
        gcp_provider = json_response['provider_gcp']

        expect(gcp_provider['cluster_id']).to eq(cluster.id)
        expect(gcp_provider['status_name']).to eq('created')
        expect(gcp_provider['gcp_project_id']).to eq('test-gcp-project')
        expect(gcp_provider['zone']).to eq('us-central1-a')
        expect(gcp_provider['machine_type']).to eq('n1-standard-2')
        expect(gcp_provider['num_nodes']).to eq(3)
        expect(gcp_provider['endpoint']).to eq('111.111.111.111')
      end

      context 'when cluster has no provider' do
        let(:cluster) do
          create(:cluster, :project, :provided_by_user,
                 projects: [project])
        end

        it 'does not include GCP provider info' do
          expect(json_response['provider_gcp']).not_to be_present
        end
      end

      context 'with non-existing cluster' do
        let(:cluster_id) { 123 }

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'POST /projects/:id/clusters/user' do
    let(:api_url) { 'https://kubernetes.example.com' }
    let(:namespace) { project.path }
    let(:authorization_type) { 'rbac' }

    let(:platform_kubernetes_attributes) do
      {
        api_url: api_url,
        token: 'sample-token',
        namespace: namespace,
        authorization_type: authorization_type
      }
    end

    let(:cluster_params) do
      {
        name: 'test-cluster',
        domain: 'domain.example.com',
        managed: false,
        platform_kubernetes_attributes: platform_kubernetes_attributes
      }
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        post api("/projects/#{project.id}/clusters/user", developer_user), params: cluster_params

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        post api("/projects/#{project.id}/clusters/user", current_user), params: cluster_params
      end

      context 'with valid params' do
        it 'responds with 201' do
          expect(response).to have_gitlab_http_status(201)
        end

        it 'creates a new Cluster::Cluster' do
          cluster_result = Clusters::Cluster.find(json_response["id"])
          platform_kubernetes = cluster_result.platform

          expect(cluster_result).to be_user
          expect(cluster_result).to be_kubernetes
          expect(cluster_result.project).to eq(project)
          expect(cluster_result.name).to eq('test-cluster')
          expect(cluster_result.domain).to eq('domain.example.com')
          expect(cluster_result.managed).to be_falsy
          expect(platform_kubernetes.rbac?).to be_truthy
          expect(platform_kubernetes.api_url).to eq(api_url)
          expect(platform_kubernetes.namespace).to eq(namespace)
          expect(platform_kubernetes.token).to eq('sample-token')
        end
      end

      context 'when user does not indicate authorization type' do
        let(:platform_kubernetes_attributes) do
          {
            api_url: api_url,
            token: 'sample-token',
            namespace: namespace
          }
        end

        it 'defaults to RBAC' do
          cluster_result = Clusters::Cluster.find(json_response['id'])

          expect(cluster_result.platform_kubernetes.rbac?).to be_truthy
        end
      end

      context 'when user sets authorization type as ABAC' do
        let(:authorization_type) { 'abac' }

        it 'creates an ABAC cluster' do
          cluster_result = Clusters::Cluster.find(json_response['id'])

          expect(cluster_result.platform.abac?).to be_truthy
        end
      end

      context 'with invalid params' do
        let(:namespace) { 'invalid_namespace' }

        it 'responds with 400' do
          expect(response).to have_gitlab_http_status(400)
        end

        it 'does not create a new Clusters::Cluster' do
          expect(project.reload.clusters).to be_empty
        end

        it 'returns validation errors' do
          expect(json_response['message']['platform_kubernetes.namespace'].first).to be_present
        end
      end
    end

    context 'when user tries to add multiple clusters' do
      before do
        create(:cluster, :provided_by_gcp, :project,
               projects: [project])

        post api("/projects/#{project.id}/clusters/user", current_user), params: cluster_params
      end

      it 'responds with 400' do
        expect(response).to have_gitlab_http_status(400)

        expect(json_response['message']['base'].first).to eq(_('Instance does not support multiple Kubernetes clusters'))
      end
    end

    context 'non-authorized user' do
      before do
        post api("/projects/#{project.id}/clusters/user", developer_user), params: cluster_params
      end

      it 'responds with 403' do
        expect(response).to have_gitlab_http_status(403)

        expect(json_response['message']).to eq('403 Forbidden')
      end
    end
  end

  describe 'PUT /projects/:id/clusters/:cluster_id' do
    let(:api_url) { 'https://kubernetes.example.com' }
    let(:namespace) { 'new-namespace' }
    let(:platform_kubernetes_attributes) { { namespace: namespace } }
    let(:management_project) { create(:project, namespace: project.namespace) }
    let(:management_project_id) { management_project.id }

    let(:update_params) do
      {
        domain: 'new-domain.com',
        platform_kubernetes_attributes: platform_kubernetes_attributes,
        management_project_id: management_project_id
      }
    end

    let!(:kubernetes_namespace) do
      create(:cluster_kubernetes_namespace,
             cluster: cluster,
             project: project)
    end

    let(:cluster) do
      create(:cluster, :project, :provided_by_gcp,
             projects: [project])
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        put api("/projects/#{project.id}/clusters/#{cluster.id}", developer_user), params: update_params

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        management_project.add_maintainer(current_user)

        put api("/projects/#{project.id}/clusters/#{cluster.id}", current_user), params: update_params

        cluster.reload
      end

      context 'with valid params' do
        it 'responds with 200' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'updates cluster attributes' do
          expect(cluster.domain).to eq('new-domain.com')
          expect(cluster.platform_kubernetes.namespace).to eq('new-namespace')
          expect(cluster.management_project).to eq(management_project)
        end
      end

      context 'with invalid params' do
        let(:namespace) { 'invalid_namespace' }

        it 'responds with 400' do
          expect(response).to have_gitlab_http_status(400)
        end

        it 'does not update cluster attributes' do
          expect(cluster.domain).not_to eq('new_domain.com')
          expect(cluster.platform_kubernetes.namespace).not_to eq('invalid_namespace')
          expect(cluster.management_project).not_to eq(management_project)
        end

        it 'returns validation errors' do
          expect(json_response['message']['platform_kubernetes.namespace'].first).to match('can contain only lowercase letters')
        end
      end

      context 'current user does not have access to management_project_id' do
        let(:management_project_id) { create(:project).id }

        it 'responds with 400' do
          expect(response).to have_gitlab_http_status(400)
        end

        it 'returns validation errors' do
          expect(json_response['message']['management_project_id'].first).to match('don\'t have permission')
        end
      end

      context 'with a GCP cluster' do
        context 'when user tries to change GCP specific fields' do
          let(:platform_kubernetes_attributes) do
            {
              api_url: 'https://new-api-url.com',
              token: 'new-sample-token'
            }
          end

          it 'responds with 400' do
            expect(response).to have_gitlab_http_status(400)
          end

          it 'returns validation error' do
            expect(json_response['message']['platform_kubernetes.base'].first).to eq(_('Cannot modify managed Kubernetes cluster'))
          end
        end

        context 'when user tries to change namespace' do
          let(:namespace) { 'new-namespace' }

          it 'responds with 200' do
            expect(response).to have_gitlab_http_status(200)
          end
        end
      end

      context 'with an user cluster' do
        let(:api_url) { 'https://new-api-url.com' }

        let(:cluster) do
          create(:cluster, :project, :provided_by_user,
                 projects: [project])
        end

        let(:platform_kubernetes_attributes) do
          {
            api_url: api_url,
            namespace: 'new-namespace',
            token: 'new-sample-token'
          }
        end

        let(:update_params) do
          {
            name: 'new-name',
            platform_kubernetes_attributes: platform_kubernetes_attributes
          }
        end

        it 'responds with 200' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'updates platform kubernetes attributes' do
          platform_kubernetes = cluster.platform_kubernetes

          expect(cluster.name).to eq('new-name')
          expect(platform_kubernetes.namespace).to eq('new-namespace')
          expect(platform_kubernetes.api_url).to eq('https://new-api-url.com')
          expect(platform_kubernetes.token).to eq('new-sample-token')
        end
      end

      context 'with a cluster that does not belong to user' do
        let(:cluster) { create(:cluster, :project, :provided_by_user) }

        it 'responds with 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/clusters/:cluster_id' do
    let(:cluster_params) { { cluster_id: cluster.id } }

    let(:cluster) do
      create(:cluster, :project, :provided_by_gcp,
             projects: [project])
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        delete api("/projects/#{project.id}/clusters/#{cluster.id}", developer_user), params: cluster_params

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        delete api("/projects/#{project.id}/clusters/#{cluster.id}", current_user), params: cluster_params
      end

      it 'responds with 204' do
        expect(response).to have_gitlab_http_status(204)
      end

      it 'deletes the cluster' do
        expect(Clusters::Cluster.exists?(id: cluster.id)).to be_falsy
      end

      context 'with a cluster that does not belong to user' do
        let(:cluster) { create(:cluster, :project, :provided_by_user) }

        it 'responds with 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
