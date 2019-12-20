# frozen_string_literal: true

require 'spec_helper'

describe API::GroupClusters do
  include KubernetesHelpers

  let(:current_user) { create(:user) }
  let(:developer_user) { create(:user) }
  let(:group) { create(:group, :private) }

  before do
    group.add_developer(developer_user)
    group.add_maintainer(current_user)
  end

  describe 'GET /groups/:id/clusters' do
    let!(:extra_cluster) { create(:cluster, :provided_by_gcp, :group) }

    let!(:clusters) do
      create_list(:cluster, 5, :provided_by_gcp, :group, :production_environment,
                  groups: [group])
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        get api("/groups/#{group.id}/clusters", developer_user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        get api("/groups/#{group.id}/clusters", current_user)
      end

      it 'responds with 200' do
        expect(response).to have_gitlab_http_status(200)
      end

      it 'includes pagination headers' do
        expect(response).to include_pagination_headers
      end

      it 'only include authorized clusters' do
        cluster_ids = json_response.map { |cluster| cluster['id'] }

        expect(cluster_ids).to match_array(clusters.pluck(:id))
        expect(cluster_ids).not_to include(extra_cluster.id)
      end
    end
  end

  describe 'GET /groups/:id/clusters/:cluster_id' do
    let(:cluster_id) { cluster.id }

    let(:platform_kubernetes) do
      create(:cluster_platform_kubernetes, :configured)
    end

    let(:cluster) do
      create(:cluster, :group, :provided_by_gcp, :with_domain,
             platform_kubernetes: platform_kubernetes,
             user: current_user,
             groups: [group])
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        get api("/groups/#{group.id}/clusters/#{cluster_id}", developer_user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        get api("/groups/#{group.id}/clusters/#{cluster_id}", current_user)
      end

      it 'returns specific cluster' do
        expect(json_response['id']).to eq(cluster.id)
      end

      it 'returns cluster information' do
        expect(json_response['provider_type']).to eq('gcp')
        expect(json_response['platform_type']).to eq('kubernetes')
        expect(json_response['environment_scope']).to eq('*')
        expect(json_response['cluster_type']).to eq('group_type')
        expect(json_response['domain']).to eq('example.com')
      end

      it 'returns group information' do
        cluster_group = json_response['group']

        expect(cluster_group['id']).to eq(group.id)
        expect(cluster_group['name']).to eq(group.name)
        expect(cluster_group['web_url']).to eq(group.web_url)
      end

      it 'returns kubernetes platform information' do
        platform = json_response['platform_kubernetes']

        expect(platform['api_url']).to eq('https://kubernetes.example.com')
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
          create(:cluster, :group, :provided_by_user,
                 groups: [group])
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

  shared_context 'kubernetes calls stubbed' do
    before do
      stub_kubeclient_discover(api_url)
    end
  end

  describe 'POST /groups/:id/clusters/user' do
    include_context 'kubernetes calls stubbed'

    let(:api_url) { 'https://kubernetes.example.com' }
    let(:authorization_type) { 'rbac' }

    let(:platform_kubernetes_attributes) do
      {
        api_url: api_url,
        token: 'sample-token',
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
        post api("/groups/#{group.id}/clusters/user", developer_user), params: cluster_params

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        post api("/groups/#{group.id}/clusters/user", current_user), params: cluster_params
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
          expect(cluster_result.group).to eq(group)
          expect(cluster_result.name).to eq('test-cluster')
          expect(cluster_result.domain).to eq('domain.example.com')
          expect(cluster_result.managed).to be_falsy
          expect(platform_kubernetes.rbac?).to be_truthy
          expect(platform_kubernetes.api_url).to eq(api_url)
          expect(platform_kubernetes.token).to eq('sample-token')
        end
      end

      context 'when user does not indicate authorization type' do
        let(:platform_kubernetes_attributes) do
          {
            api_url: api_url,
            token: 'sample-token'
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
        let(:api_url) { 'invalid_api_url' }

        it 'responds with 400' do
          expect(response).to have_gitlab_http_status(400)
        end

        it 'does not create a new Clusters::Cluster' do
          expect(group.reload.clusters).to be_empty
        end

        it 'returns validation errors' do
          expect(json_response['message']['platform_kubernetes.api_url'].first).to be_present
        end
      end
    end

    context 'when user tries to add multiple clusters' do
      before do
        create(:cluster, :provided_by_gcp, :group,
               groups: [group])

        post api("/groups/#{group.id}/clusters/user", current_user), params: cluster_params
      end

      it 'responds with 400' do
        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']['base'].first).to eq(_('Instance does not support multiple Kubernetes clusters'))
      end
    end

    context 'non-authorized user' do
      before do
        post api("/groups/#{group.id}/clusters/user", developer_user), params: cluster_params
      end

      it 'responds with 403' do
        expect(response).to have_gitlab_http_status(403)

        expect(json_response['message']).to eq('403 Forbidden')
      end
    end
  end

  describe 'PUT /groups/:id/clusters/:cluster_id' do
    include_context 'kubernetes calls stubbed'

    let(:api_url) { 'https://kubernetes.example.com' }

    let(:update_params) do
      {
        domain: domain,
        platform_kubernetes_attributes: platform_kubernetes_attributes,
        management_project_id: management_project_id
      }
    end

    let(:domain) { 'new-domain.com' }
    let(:platform_kubernetes_attributes) { {} }
    let(:management_project) { create(:project, group: group) }
    let(:management_project_id) { management_project.id }

    let(:cluster) do
      create(:cluster, :group, :provided_by_gcp,
             groups: [group], domain: 'old-domain.com')
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        put api("/groups/#{group.id}/clusters/#{cluster.id}", developer_user), params: update_params

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        management_project.add_maintainer(current_user)

        put api("/groups/#{group.id}/clusters/#{cluster.id}", current_user), params: update_params

        cluster.reload
      end

      context 'with valid params' do
        it 'responds with 200' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'updates cluster attributes' do
          expect(cluster.domain).to eq('new-domain.com')
          expect(cluster.management_project).to eq(management_project)
        end
      end

      context 'with invalid params' do
        let(:domain) { 'invalid domain' }

        it 'responds with 400' do
          expect(response).to have_gitlab_http_status(400)
        end

        it 'does not update cluster attributes' do
          expect(cluster.domain).to eq('old-domain.com')
          expect(cluster.management_project).to be_nil
        end

        it 'returns validation errors' do
          expect(json_response['message']['domain'].first).to match('contains invalid characters (valid characters: [a-z0-9\\-])')
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

        context 'when user tries to change domain' do
          let(:domain) { 'new-domain.com' }

          it 'responds with 200' do
            expect(response).to have_gitlab_http_status(200)
          end
        end
      end

      context 'with an user cluster' do
        let(:api_url) { 'https://new-api-url.com' }

        let(:cluster) do
          create(:cluster, :group, :provided_by_user,
                 groups: [group])
        end

        let(:platform_kubernetes_attributes) do
          {
            api_url: api_url,
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
          expect(platform_kubernetes.api_url).to eq('https://new-api-url.com')
          expect(platform_kubernetes.token).to eq('new-sample-token')
        end
      end

      context 'with a cluster that does not belong to user' do
        let(:cluster) { create(:cluster, :group, :provided_by_user) }

        it 'responds with 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'DELETE /groups/:id/clusters/:cluster_id' do
    let(:cluster_params) { { cluster_id: cluster.id } }

    let(:cluster) do
      create(:cluster, :group, :provided_by_gcp,
             groups: [group])
    end

    context 'non-authorized user' do
      it 'responds with 403' do
        delete api("/groups/#{group.id}/clusters/#{cluster.id}", developer_user), params: cluster_params

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        delete api("/groups/#{group.id}/clusters/#{cluster.id}", current_user), params: cluster_params
      end

      it 'responds with 204' do
        expect(response).to have_gitlab_http_status(204)
      end

      it 'deletes the cluster' do
        expect(Clusters::Cluster.exists?(id: cluster.id)).to be_falsy
      end

      context 'with a cluster that does not belong to user' do
        let(:cluster) { create(:cluster, :group, :provided_by_user) }

        it 'responds with 404' do
          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end
end
