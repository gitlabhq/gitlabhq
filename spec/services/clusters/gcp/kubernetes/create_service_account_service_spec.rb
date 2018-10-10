# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Gcp::Kubernetes::CreateServiceAccountService, '#execute' do
  include KubernetesHelpers

  let(:service) { described_class.new(kubeclient, name: service_account_name, namespace: namespace, rbac: rbac) }
  let(:api_url) { 'http://111.111.111.111' }
  let(:platform_kubernetes) { cluster.platform_kubernetes }
  let(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster_project: cluster.cluster_projects.first) }
  let(:namespace) { kubernetes_namespace.namespace }

  let(:cluster) do
    create(:cluster,
           :project, :provided_by_gcp,
           platform_kubernetes: create(:cluster_platform_kubernetes, :configured))
  end

  let(:kubeclient) do
    Gitlab::Kubernetes::KubeClient.new(
      api_url,
      ['api', 'apis/rbac.authorization.k8s.io'],
      auth_options: { username: 'admin', password: 'password' }
    )
  end

  subject { service.execute }

  before do
    stub_kubeclient_discover(api_url)

    stub_kubeclient_get_namespace(api_url, namespace: namespace)
    stub_kubeclient_create_service_account(api_url, namespace: namespace )
    stub_kubeclient_create_secret(api_url, namespace: namespace)
  end

  shared_examples 'creates service account and token' do
    it 'creates a kubernetes service account' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts").with(
        body: hash_including(
          kind: 'ServiceAccount',
          metadata: { name: service_account_name, namespace: namespace }
        )
      )
    end

    it 'creates a kubernetes secret' do
      subject

      expect(WebMock).to have_requested(:post, api_url + "/api/v1/namespaces/#{namespace}/secrets").with(
        body: hash_including(
          kind: 'Secret',
          metadata: {
            name: token_name,
            namespace: namespace,
            annotations: {
              'kubernetes.io/service-account.name': service_account_name
            }
          },
          type: 'kubernetes.io/service-account-token'
        )
      )
    end
  end

  context 'With ABAC cluster' do
    let(:service_account_name) { 'gitlab' }
    let(:namespace) { 'default' }
    let(:rbac) { false }
    let(:token_name) { 'gitlab-token' }

    it_behaves_like 'creates service account and token'
  end

  context 'With RBAC enabled cluster' do
    let(:rbac) { true }

    before do
      cluster.platform_kubernetes.rbac!
    end

    context 'when creating default namespace' do
      let(:service_account_name) { 'gitlab' }
      let(:namespace) { 'default' }
      let(:token_name) { 'gitlab-token' }

      before do
        stub_kubeclient_create_cluster_role_binding(api_url)
      end

      it_behaves_like 'creates service account and token'

      it 'should create a cluster role binding with cluster-admin access' do
        subject

        expect(WebMock).to have_requested(:post, api_url + "/apis/rbac.authorization.k8s.io/v1/clusterrolebindings").with(
          body: hash_including(
            kind: 'ClusterRoleBinding',
            metadata: { name: 'gitlab-admin' },
            roleRef: {
              apiGroup: 'rbac.authorization.k8s.io',
              kind: 'ClusterRole',
              name: 'cluster-admin'
            },
            subjects: [
              {
                kind: 'ServiceAccount',
                name: service_account_name,
                namespace: namespace
              }
            ]
          )
        )
      end
    end

    context 'when creating project namespace' do
      let(:service_account_name) { "#{namespace}-service-account" }
      let(:namespace) { "#{cluster.project.path}-#{cluster.project.id}" }
      let(:token_name) { "#{namespace}-token" }

      before do
        stub_kubeclient_create_role_binding(api_url, namespace: namespace)
      end

      it_behaves_like 'creates service account and token'

      it 'creates a namespaced role binding with edit access' do
        subject

        expect(WebMock).to have_requested(:post, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings").with(
          body: hash_including(
            kind: 'RoleBinding',
            metadata: { name: "gitlab-#{namespace}", namespace: "#{namespace}" },
            roleRef: {
              apiGroup: 'rbac.authorization.k8s.io',
              kind: 'Role',
              name: 'edit'
            },
            subjects: [
              {
                kind: 'ServiceAccount',
                name: service_account_name,
                namespace: namespace
              }
            ]
          )
        )
      end
    end
  end
end
