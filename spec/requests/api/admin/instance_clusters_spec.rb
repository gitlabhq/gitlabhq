# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Admin::InstanceClusters, feature_category: :deployment_management do
  include KubernetesHelpers

  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:project) { create(:project) }
  let_it_be(:project_cluster) do
    create(:cluster, :project, :provided_by_gcp, user: admin_user, projects: [project])
  end

  let(:project_cluster_id) { project_cluster.id }

  describe "GET /admin/clusters" do
    let_it_be(:path) { "/admin/clusters" }
    let_it_be(:clusters) do
      create_list(:cluster, 3, :provided_by_gcp, :instance, :production_environment)
    end

    it_behaves_like 'GET request permissions for admin mode'

    include_examples ':certificate_based_clusters feature flag API responses' do
      let(:subject) { get api(path, admin_user, admin_mode: true) }
    end

    context "when authenticated as admin" do
      before do
        get api(path, admin_user, admin_mode: true)
      end

      it 'includes pagination headers' do
        expect(response).to include_pagination_headers
      end

      it 'only returns the instance clusters', :aggregate_failures do
        cluster_ids = json_response.map { |cluster| cluster['id'] }
        expect(cluster_ids).to match_array(clusters.pluck(:id))
        expect(cluster_ids).not_to include(project_cluster_id)
      end
    end
  end

  describe "GET /admin/clusters/:cluster_id" do
    let_it_be(:platform_kubernetes) do
      create(:cluster_platform_kubernetes, :configured)
    end

    let_it_be(:cluster) do
      create(:cluster, :instance, :provided_by_gcp, :with_domain,
        { platform_kubernetes: platform_kubernetes,
          user: admin_user })
    end

    let(:cluster_id) { cluster.id }

    let(:path) { "/admin/clusters/#{cluster_id}" }

    it_behaves_like 'GET request permissions for admin mode'

    include_examples ':certificate_based_clusters feature flag API responses' do
      let(:subject) { get api(path, admin_user, admin_mode: true) }
    end

    context "when authenticated as admin" do
      before do
        get api(path, admin_user, admin_mode: true)
      end

      context "when no cluster associated to the ID" do
        let(:cluster_id) { 1337 }

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context "when cluster with cluster_id exists" do
        it 'returns the cluster with cluster_id' do
          expect(json_response['id']).to eq(cluster.id)
        end

        it 'returns the cluster information', :aggregate_failures do
          expect(json_response['provider_type']).to eq('gcp')
          expect(json_response['platform_type']).to eq('kubernetes')
          expect(json_response['environment_scope']).to eq('*')
          expect(json_response['cluster_type']).to eq('instance_type')
          expect(json_response['domain']).to eq('example.com')
          expect(json_response['enabled']).to be_truthy
          expect(json_response['managed']).to be_truthy
        end

        it 'returns kubernetes platform information', :aggregate_failures do
          platform = json_response['platform_kubernetes']

          expect(platform['api_url']).to eq('https://kubernetes.example.com')
          expect(platform['ca_cert']).to be_present
        end

        it 'returns user information', :aggregate_failures do
          user = json_response['user']

          expect(user['id']).to eq(admin_user.id)
          expect(user['username']).to eq(admin_user.username)
        end

        it 'returns GCP provider information', :aggregate_failures do
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
            create(:cluster, :instance, :provided_by_user, :production_environment)
          end

          it 'does not include GCP provider info' do
            expect(json_response['provider_gcp']).not_to be_present
          end
        end

        context 'when trying to get a project cluster via the instance cluster endpoint' do
          it 'returns 404' do
            get api("/admin/clusters/#{project_cluster_id}", admin_user, admin_mode: true)
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe "POST /admin/clusters/add" do
    let(:api_url) { 'https://example.com' }
    let(:authorization_type) { 'rbac' }
    let(:clusterable) { Clusters::Instance.new }
    let_it_be(:path) { '/admin/clusters/add' }

    let(:platform_kubernetes_attributes) do
      {
        api_url: api_url,
        token: 'sample-token',
        authorization_type: authorization_type
      }
    end

    let(:cluster_params) do
      {
        name: 'test-instance-cluster',
        domain: 'domain.example.com',
        managed: false,
        enabled: false,
        namespace_per_environment: false,
        platform_kubernetes_attributes: platform_kubernetes_attributes,
        clusterable: clusterable
      }
    end

    let(:multiple_cluster_params) do
      {
        name: 'multiple-instance-cluster',
        environment_scope: 'staging/*',
        platform_kubernetes_attributes: platform_kubernetes_attributes
      }
    end

    let(:invalid_cluster_params) do
      {
        environment_scope: 'production/*',
        domain: 'domain.example.com',
        platform_kubernetes_attributes: platform_kubernetes_attributes
      }
    end

    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { cluster_params }
    end

    include_examples ':certificate_based_clusters feature flag API responses' do
      let(:subject) { post api(path, admin_user, admin_mode: true), params: cluster_params }
    end

    context 'authorized user' do
      before do
        post api(path, admin_user, admin_mode: true), params: cluster_params
      end

      context 'with valid params' do
        it 'creates a new Clusters::Cluster', :aggregate_failures do
          cluster_result = Clusters::Cluster.find(json_response["id"])
          platform_kubernetes = cluster_result.platform
          expect(cluster_result).to be_user
          expect(cluster_result).to be_kubernetes
          expect(cluster_result.clusterable).to be_a Clusters::Instance
          expect(cluster_result.cluster_type).to eq('instance_type')
          expect(cluster_result.name).to eq('test-instance-cluster')
          expect(cluster_result.domain).to eq('domain.example.com')
          expect(cluster_result.environment_scope).to eq('*')
          expect(cluster_result.managed).to be_falsy
          expect(cluster_result.enabled).to be_falsy
          expect(platform_kubernetes.authorization_type).to eq('rbac')
          expect(cluster_result.namespace_per_environment).to eq(false)
          expect(platform_kubernetes.api_url).to eq("https://example.com")
          expect(platform_kubernetes.token).to eq('sample-token')
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

        context 'when namespace_per_environment is not set' do
          let(:cluster_params) do
            {
              name: 'test-cluster',
              domain: 'domain.example.com',
              platform_kubernetes_attributes: platform_kubernetes_attributes
            }
          end

          it 'defaults to true' do
            cluster_result = Clusters::Cluster.find(json_response['id'])

            expect(cluster_result).to be_namespace_per_environment
          end
        end

        context 'when an instance cluster already exists' do
          it 'allows user to add multiple clusters' do
            post api(path, admin_user, admin_mode: true), params: multiple_cluster_params

            expect(Clusters::Instance.new.clusters.count).to eq(2)
          end
        end
      end

      context 'with invalid params' do
        context 'when missing a required parameter' do
          it 'responds with 400', :aggregate_failures do
            post api(path, admin_user, admin_mode: true), params: invalid_cluster_params
            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eql('name is missing')
          end
        end

        context 'with a malformed api url' do
          let(:api_url) { 'invalid_api_url' }

          it 'responds with 400' do
            expect(response).to have_gitlab_http_status(:bad_request)
          end

          it 'returns validation errors' do
            expect(json_response['message']['platform_kubernetes.api_url'].first).to be_present
          end
        end
      end
    end
  end

  describe 'PUT /admin/clusters/:cluster_id' do
    let(:api_url) { 'https://example.com' }

    let(:update_params) do
      {
        domain: domain,
        managed: false,
        enabled: false,
        platform_kubernetes_attributes: platform_kubernetes_attributes
      }
    end

    let(:domain) { 'new-domain.com' }
    let(:platform_kubernetes_attributes) { {} }

    let_it_be(:cluster) do
      create(:cluster, :instance, :provided_by_gcp, domain: 'old-domain.com')
    end

    let(:path) { "/admin/clusters/#{cluster.id}" }

    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { update_params }
    end

    include_examples ':certificate_based_clusters feature flag API responses' do
      let(:subject) { put api(path, admin_user, admin_mode: true), params: update_params }
    end

    context 'authorized user' do
      before do
        put api(path, admin_user, admin_mode: true), params: update_params

        cluster.reload
      end

      context 'with valid params' do
        it 'updates cluster attributes', :aggregate_failures do
          expect(cluster.domain).to eq('new-domain.com')
          expect(cluster.managed).to be_falsy
          expect(cluster.enabled).to be_falsy
        end
      end

      context 'with invalid params' do
        let(:domain) { 'invalid domain' }

        it 'responds with 400' do
          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'does not update cluster attributes', :aggregate_failures do
          expect(cluster.domain).to eq('old-domain.com')
          expect(cluster.managed).to be_truthy
          expect(cluster.enabled).to be_truthy
        end

        it 'returns validation errors' do
          expect(json_response['message']['domain'].first).to match('contains invalid characters (valid characters: [a-z0-9\\-])')
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
            expect(response).to have_gitlab_http_status(:bad_request)
          end

          it 'returns validation error' do
            expect(json_response['message']['platform_kubernetes.base'].first).to eq(_('Cannot modify managed Kubernetes cluster'))
          end
        end

        context 'when user tries to change domain' do
          let(:domain) { 'new-domain.com' }

          it 'responds with 200' do
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context 'with an user cluster' do
        let(:api_url) { 'https://new-api-url.com' }

        let(:cluster) do
          create(:cluster, :instance, :provided_by_user, :production_environment)
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
          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'updates platform kubernetes attributes', :aggregate_failures do
          platform_kubernetes = cluster.platform_kubernetes

          expect(cluster.name).to eq('new-name')
          expect(platform_kubernetes.api_url).to eq('https://new-api-url.com')
          expect(platform_kubernetes.token).to eq('new-sample-token')
        end
      end

      context 'with a cluster that does not exist' do
        let(:cluster_id) { 1337 }

        it 'returns 404' do
          put api("/admin/clusters/#{cluster_id}", admin_user, admin_mode: true), params: update_params
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when trying to update a project cluster via the instance cluster endpoint' do
        it 'returns 404' do
          put api("/admin/clusters/#{project_cluster_id}", admin_user, admin_mode: true), params: update_params
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'DELETE /admin/clusters/:cluster_id' do
    let(:cluster_params) { { cluster_id: cluster.id } }

    let_it_be(:cluster) do
      create(:cluster, :instance, :provided_by_gcp)
    end

    let_it_be(:path) { "/admin/clusters/#{cluster.id}" }

    it_behaves_like 'DELETE request permissions for admin mode'

    include_examples ':certificate_based_clusters feature flag API responses' do
      let(:subject) { delete api(path, admin_user, admin_mode: true), params: cluster_params }
    end

    context 'authorized user' do
      before do
        delete api(path, admin_user, admin_mode: true), params: cluster_params
      end

      it 'deletes the cluster' do
        expect(Clusters::Cluster.exists?(id: cluster.id)).to be_falsy
      end

      context 'with a cluster that does not exist' do
        let(:cluster_id) { 1337 }

        it 'returns 404' do
          delete api(path, admin_user, admin_mode: true)
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when trying to update a project cluster via the instance cluster endpoint' do
        it 'returns 404' do
          delete api("/admin/clusters/#{project_cluster_id}", admin_user, admin_mode: true)
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
